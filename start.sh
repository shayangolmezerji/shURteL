#!/bin/bash
# URL Shortener (FastAPI / Redis / Bash)

# --- Bash Setup ---
log_info() { echo -e "\n\033[32m[INFO]\033[0m $1"; }
log_error() { echo -e "\n\033[31m[ERROR]\033[0m $1"; exit 1; }

check_prerequisites() {
    log_info "Setup started."
    command -v redis-server &> /dev/null || log_error "Install redis-server."
    command -v python3 &> /dev/null || log_error "Install Python 3 and pip 3."
    
    log_info "Installing dependencies."
    pip3 install fastapi uvicorn redis || log_error "Dependency install failed."
}

run_services() {
    log_info "Pinging Redis."
    if ! redis-cli ping &> /dev/null; then
        log_info "Starting Redis."
        redis-server &
        sleep 2
        redis-cli ping &> /dev/null || log_error "Redis connection failed."
    fi

    log_info "Starting FastAPI at http://127.0.0.1:8000 (Ctrl+C to stop)."
    sed -n '/^# --- START PYTHON CODE ---/,$p' "$0" | sed '1d' > url_shortener.py
    uvicorn url_shortener:app --host 0.0.0.0 --port 8000
    rm url_shortener.py
}

if [[ "$1" == "run" ]]; then
    check_prerequisites
    run_services
else
    echo "Usage: bash $0 run"
fi
exit 0 

# --- START PYTHON CODE ---
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
import redis
import secrets
import string
import os

# --- Config/Setup ---
try:
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    r = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    r.ping() 
except redis.exceptions.ConnectionError:
    print("FATAL: Redis down.")
    exit(1)

app = FastAPI()
SHORT_CODE_LENGTH = 7
BASE_CHARS = string.ascii_letters + string.digits 

# --- Pydantic Models ---
class URLToShorten(BaseModel):
    url: str
    
class ShortURLInfo(BaseModel):
    short_url: str
    original_url: str
    clicks: int

# --- Core Logic ---
def generate_unique_code() -> str:
    while True:
        code = ''.join(secrets.choice(BASE_CHARS) for _ in range(SHORT_CODE_LENGTH))
        if not r.exists(f"link:{code}"): return code

def store_url(long_url: str) -> str:
    short_code = generate_unique_code()
    r.hset(f"link:{short_code}", mapping={"url": long_url, "clicks": 0})
    return short_code

def get_url_and_increment_clicks(short_code: str) -> str | None:
    pipe = r.pipeline()
    pipe.hget(f"link:{short_code}", "url")
    pipe.hincrby(f"link:{short_code}", "clicks", 1)
    results = pipe.execute()
    return results[0]

# --- FastAPI Routes ---

# 1. Redirect
@app.get("/{short_code}", response_class=RedirectResponse)
async def redirect(short_code: str):
    long_url = get_url_and_increment_clicks(short_code)
    if long_url: return RedirectResponse(url=long_url, status_code=307)
    raise HTTPException(status_code=404, detail="404")

# 2. Shorten API
@app.post("/api/shorten", response_model=ShortURLInfo)
async def shorten(item: URLToShorten):
    short_code = store_url(item.url)
    base_url = f"http://127.0.0.1:8000" 
    return ShortURLInfo(short_url=f"{base_url}/{short_code}", original_url=item.url, clicks=0)

# 3. Stats API
@app.get("/api/stats/{short_code}", response_model=ShortURLInfo)
async def stats(short_code: str):
    url_data = r.hgetall(f"link:{short_code}")
    if url_data and "url" in url_data and "clicks" in url_data:
        base_url = f"http://127.0.0.1:8000"
        return ShortURLInfo(short_url=f"{base_url}/{short_code}", original_url=url_data["url"], clicks=int(url_data["clicks"]))
    raise HTTPException(status_code=404, detail="404")
# Py end
