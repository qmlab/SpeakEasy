import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# On Fly.io, use persistent volume at /data for SQLite storage
_default_db = (
    "sqlite:////data/app.db" if os.path.isdir("/data") else "sqlite:///./risingstar.db"
)
DATABASE_URL = os.getenv("DATABASE_URL", _default_db)

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
