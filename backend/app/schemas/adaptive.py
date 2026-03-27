from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class DevelopmentalProfileResponse(BaseModel):
    id: str
    player_id: str
    dimension: str
    level: int
    sub_scores: Optional[dict] = None
    assessed: bool
    last_assessed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DevelopmentalProfileUpdate(BaseModel):
    level: Optional[int] = None
    sub_scores: Optional[dict] = None
    assessed: Optional[bool] = None


class FullProfileResponse(BaseModel):
    player_id: str
    player_name: str
    dimensions: list[DevelopmentalProfileResponse]
    overall_level: float


class StartSessionRequest(BaseModel):
    player_id: str
    session_type: str
    dimension: Optional[str] = None


class SessionResponse(BaseModel):
    id: str
    player_id: str
    session_type: str
    dimension: Optional[str] = None
    started_at: datetime
    ended_at: Optional[datetime] = None
    tasks_completed: int
    correct_count: int
    total_count: int
    avg_response_time_ms: Optional[float] = None
    prompt_dependency_rate: Optional[float] = None
    engagement_score: Optional[float] = None
    status: str
    current_level: int

    class Config:
        from_attributes = True


class NextTaskResponse(BaseModel):
    task_id: str
    dimension: str
    level: int
    task_type: str
    modalities: list[str]
    content: dict
    prompt_level: int
    session_id: str


class SubmitAttemptRequest(BaseModel):
    session_id: str
    task_id: str
    player_id: str
    is_correct: bool
    score: int = 0
    response_time_ms: Optional[int] = None
    prompt_level: int = 0
    response_data: Optional[dict] = None


class AttemptResultResponse(BaseModel):
    attempt_id: str
    is_correct: bool
    score: int
    reward: Optional[dict] = None
    streak: int
    accuracy: float
    should_level_up: bool
    should_level_down: bool
    confidence_rebuild: bool
    next_action: str
    level_change: int = 0


class EndSessionResponse(BaseModel):
    session_id: str
    tasks_completed: int
    correct_count: int
    total_count: int
    accuracy: float
    avg_response_time_ms: Optional[float] = None
    level_change: int
    rewards_earned: int


class AdaptiveTaskCreate(BaseModel):
    dimension: str
    level: int
    task_type: str
    modalities: list[str]
    content: dict
    metadata_info: Optional[dict] = None
    is_assessment: bool = False


class AdaptiveTaskResponse(BaseModel):
    id: str
    dimension: str
    level: int
    task_type: str
    modalities: list[str]
    content: dict
    metadata_info: Optional[dict] = None
    is_assessment: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ReinforcementConfigResponse(BaseModel):
    id: str
    player_id: str
    reward_frequency: int
    reward_type: str
    prompt_strategy: str
    confidence_rebuild_threshold: int
    session_max_duration_minutes: int
    break_after_minutes: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ReinforcementConfigUpdate(BaseModel):
    reward_frequency: Optional[int] = None
    reward_type: Optional[str] = None
    prompt_strategy: Optional[str] = None
    confidence_rebuild_threshold: Optional[int] = None
    session_max_duration_minutes: Optional[int] = None
    break_after_minutes: Optional[int] = None


class DashboardSummary(BaseModel):
    player_id: str
    player_name: str
    dimensions: list[DevelopmentalProfileResponse]
    recent_sessions: list[SessionResponse]
    total_sessions: int
    total_tasks_completed: int
    overall_accuracy: float
    streak_days: int
    mastered_tasks: int
    struggling_tasks: int


class DimensionProgress(BaseModel):
    dimension: str
    current_level: int
    history: list[dict]
    mastered_count: int
    total_count: int
    accuracy_trend: list[float]
