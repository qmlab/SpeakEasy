import os

# On Fly.io, use persistent volume at /data for storage
_on_fly = os.path.isdir("/data")

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:////data/app.db" if _on_fly else "sqlite:///./risingstar.db",
)

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "/data/uploads" if _on_fly else "uploads")
