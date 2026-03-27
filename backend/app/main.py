import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text, inspect

from app.database import engine, Base
from app.routers import (
    players_router,
    objects_router,
    game_router,
    progress_router,
    auth_router,
    adaptive_router,
    dashboard_router,
    tasks_router,
    ai_router,
    assessment_router,
)
from app.services import cloudinary_service

Base.metadata.create_all(bind=engine)

if cloudinary_service.configure_from_env():
    print("Cloudinary configured successfully")
else:
    print("Cloudinary not configured - image uploads will use local storage")


def run_migrations():
    inspector = inspect(engine)

    if "object_images" in inspector.get_table_names():
        columns = [col["name"] for col in inspector.get_columns("object_images")]
        if "image_type" not in columns:
            with engine.connect() as conn:
                conn.execute(
                    text(
                        "ALTER TABLE object_images ADD COLUMN image_type VARCHAR(20) DEFAULT 'flashcard'"
                    )
                )
                conn.commit()
                print("Migration: Added image_type column to object_images table")

    if "players" in inspector.get_table_names():
        columns = [col["name"] for col in inspector.get_columns("players")]
        with engine.connect() as conn:
            if "apple_user_id" not in columns:
                conn.execute(
                    text("ALTER TABLE players ADD COLUMN apple_user_id VARCHAR")
                )
                conn.commit()
                print("Migration: Added apple_user_id column to players table")
            if "device_id" not in columns:
                conn.execute(text("ALTER TABLE players ADD COLUMN device_id VARCHAR"))
                conn.commit()
                print("Migration: Added device_id column to players table")
            if "email" not in columns:
                conn.execute(text("ALTER TABLE players ADD COLUMN email VARCHAR"))
                conn.commit()
                print("Migration: Added email column to players table")
            if "is_guest" not in columns:
                conn.execute(
                    text(
                        "ALTER TABLE players ADD COLUMN is_guest VARCHAR DEFAULT 'false'"
                    )
                )
                conn.commit()
                print("Migration: Added is_guest column to players table")
            if "age" not in columns:
                conn.execute(text("ALTER TABLE players ADD COLUMN age INTEGER"))
                conn.commit()
                print("Migration: Added age column to players table")


run_migrations()

app = FastAPI(
    title="Rising Star Kid API",
    description="Backend API for Rising Star Kid - Adaptive learning platform for children with autism",
    version="1.0.0",
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
app.include_router(progress_router)
app.include_router(auth_router)
app.include_router(adaptive_router)
app.include_router(dashboard_router)
app.include_router(tasks_router)
app.include_router(ai_router)
app.include_router(assessment_router)


@app.get("/")
def root():
    return {
        "message": "Welcome to Rising Star Kid API",
        "docs": "/docs",
        "features": [
            "Feature 1: See picture, say the word - Speech scoring",
            "Feature 2: Find object in picture - Location-based game",
            "Feature 3: Adaptive learning engine with multi-dimensional profiles",
            "Feature 4: ABA-based reinforcement system",
            "Feature 5: Parent/therapist dashboard",
            "Feature 6: AI-powered personalization (social stories, behavior guidance, progress summaries)",
            "Feature 7: Gamified initial assessment with animal character guides",
        ],
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}
