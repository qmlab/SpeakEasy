from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class AttemptCreate(BaseModel):
    player_id: str
    object_id: str
    feature_type: int = Field(..., ge=1, le=2, description="1 = say word, 2 = find object")
    score: int = Field(..., ge=0, le=100)
    spoken_text: Optional[str] = None
    tap_x: Optional[float] = None
    tap_y: Optional[float] = None
    is_correct: bool


class AttemptResponse(BaseModel):
    id: str
    player_id: str
    object_id: str
    feature_type: int
    score: int
    spoken_text: Optional[str]
    tap_x: Optional[float]
    tap_y: Optional[float]
    is_correct: bool
    created_at: datetime

    class Config:
        from_attributes = True


class SayWordRequest(BaseModel):
    player_id: str
    object_id: str
    spoken_text: str


class SayWordResponse(BaseModel):
    score: int
    is_correct: bool
    target_word: str
    spoken_text: str
    feedback: str
    attempt_id: str


class FindObjectRequest(BaseModel):
    player_id: str
    object_image_id: str
    tap_x: float = Field(..., ge=0, le=1, description="X coordinate of tap (0-1 normalized)")
    tap_y: float = Field(..., ge=0, le=1, description="Y coordinate of tap (0-1 normalized)")


class FindObjectResponse(BaseModel):
    is_correct: bool
    score: int
    feedback: str
    correct_location: Optional[dict] = None
    attempt_id: str
