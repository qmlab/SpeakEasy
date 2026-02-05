from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PlayerCreate(BaseModel):
    name: str


class AppleSignInRequest(BaseModel):
    apple_user_id: str
    name: Optional[str] = None
    email: Optional[str] = None


class AppleSignInResponse(BaseModel):
    id: str
    name: str
    apple_user_id: str
    email: Optional[str] = None
    is_new_user: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class GuestSignInRequest(BaseModel):
    device_id: str


class GuestSignInResponse(BaseModel):
    id: str
    name: str
    device_id: str
    is_guest: bool
    is_new_user: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlayerResponse(BaseModel):
    id: str
    name: str
    apple_user_id: Optional[str] = None
    device_id: Optional[str] = None
    email: Optional[str] = None
    is_guest: bool = False
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
