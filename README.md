# shURteL: A Scalable, Single-File Link Shortener 🚀

Honestly, I just wanted a fast URL shortener that wasn't bloated with a heavy SQL database. This project, **shURteL**, is what came out of it. It's built to be fast and easy to deploy.

---

### ✨ The Gist of It

 * **Speed is Everything:** **Redis** handles all the link lookups.
 * **Single File Magic:** Everything you need is in one `url_shortener.sh` file.
 * **Accurate Stats:** We use atomic operations in Redis to count clicks. That means even if 1,000 people click at the exact same moment, the count is perfect.
 * **Clean API:** FastAPI automatically gives us sweet, simple endpoints for shortening, redirecting, and getting click stats.

---

### 🚀 To Get It Running

Super easy. You need **Python 3**, **pip**, and a local **Redis server** running (default port 6379).

#### 1. Grab the code

```bash
git clone https://github.com/shayangolmezerji/shurtel.git
cd shurtel
````

#### 2\. Run the script

The script handles installing the Python stuff (`fastapi`, `uvicorn`, etc.) and making sure Redis is ready.

```bash
# This does the setup, checks Redis, and starts the API on port 8000
bash url_shortener.sh run
```
BTW you need Python env. so make that before running the script:

```python
python -m venv env && source env/bin/activate
```

-----

### 🧠 How to Use It

Once the server is running, hit it up at `http://127.0.0.1:8000`.

#### 1\. Make a Short Link

Hit the shorten endpoint with your long URL.

```bash
curl -X POST http://127.0.0.1:8000/api/shorten \
-H 'Content-Type: application/json' \
-d '{"url": "https://www.i-like-fastapi.com/more-than-flask"}'
```

#### 2\. Test the Redirect

Take the short code it gives you (like `ABCDEFG`) and either drop it in your browser or run this:

```bash
# The -L flag follows the redirect. This also adds +1 to your click count.
curl -s -L http://127.0.0.1:8000/ABCDEFG
```

#### 3\. Check the Clicks

See if the click counter is working.

```bash
# Check the stats for that code
curl http://127.0.0.1:8000/api/stats/ABCDEFG
```

-----

### 📜 License

This project is licensed under the [Attribution-NonCommercial 4.0 International](LICENSE.md).

### 👨‍💻 Author

Made with ❤️ by [Shayan Golmezerji](https://github.com/shayangolmezerji)
