import os
from fastapi import FastAPI

app = FastAPI(title="Secure API", version="1.0.0")

@app.get("/")
def root():
    return {"message": "Hello from Secure API"}

@app.get("/whoami")
def whoami():
    return {
        "user": os.getenv("USER", "unknown"),
        "uid": os.getuid(),
        "gid": os.getgid(),
        "home": os.getenv("HOME", "unknown")
    }

@app.get("/health")
def health():
    return {"status": "healthy"}