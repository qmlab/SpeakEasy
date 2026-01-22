from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ProgressBase(BaseModel):
    object_id: str
    last_rating: float = 0.0
    practice_count: int = 0
    consecutive_failed_attempts: int = 0
    is_learned: bool = False


class ProgressCreate(BaseModel):
    player_id: str
    object_id: str
    rating: float


class ProgressResponse(ProgressBase):
    id: str
    player_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ProgressSummary(BaseModel):
    player_id: str
    total_learned: int
    total_stars: int
    progress_by_object: dict[str, ProgressResponse]


class RecordProgressRequest(BaseModel):
    player_id: str
    object_id: str
    rating: float


class RecordProgressResponse(BaseModel):
    success: bool
    is_learned: bool
    last_rating: float
    practice_count: int
    consecutive_failed_attempts: int
    message: str
