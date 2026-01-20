import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text, inspect

from app.database import engine, Base
from app.routers import players_router, objects_router, game_router

Base.metadata.create_all(bind=engine)

def run_migrations():
    inspector = inspect(engine)
    if 'object_images' in inspector.get_table_names():
        columns = [col['name'] for col in inspector.get_columns('object_images')]
        if 'image_type' not in columns:
            with engine.connect() as conn:
                conn.execute(text("ALTER TABLE object_images ADD COLUMN image_type VARCHAR(20) DEFAULT 'flashcard'"))
                conn.commit()
                print("Migration: Added image_type column to object_images table")

run_migrations()

app = FastAPI(
    title="SpeakEasy API",
    description="Backend API for SpeakEasy - Teaching non-verbal autistic children to speak and recognize objects",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.include_router(players_router)
app.include_router(objects_router)
app.include_router(game_router)


@app.get("/")
def root():
    return {
        "message": "Welcome to SpeakEasy API",
        "docs": "/docs",
        "features": [
            "Feature 1: See picture, say the word - Speech scoring",
            "Feature 2: Find object in picture - Location-based game"
        ]
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}
