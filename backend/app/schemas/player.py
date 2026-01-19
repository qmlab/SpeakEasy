from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PlayerCreate(BaseModel):
    name: str


class PlayerResponse(BaseModel):
    id: str
    name: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlayerStats(BaseModel):
    player_id: str
    player_name: str
    total_attempts: int
    correct_attempts: int
    accuracy_percentage: float
    say_word_attempts: int
    say_word_correct: int
    find_object_attempts: int
    find_object_correct: int
    average_score: float
