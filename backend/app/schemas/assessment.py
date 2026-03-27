"""Pydantic schemas for gamified initial assessment endpoints."""

from typing import Optional
from pydantic import BaseModel, Field


# -- Assessment Start --


class AssessmentStartResponse(BaseModel):
    assessment_id: str
    player_id: str
    character: dict = Field(
        description="Animal guide character info (name, emoji, greeting)"
    )
    story_intro: str = Field(description="Narrative intro for the assessment game")
    total_activities: int = Field(description="Estimated number of activities")


# -- Assessment Activity --


class ActivityContent(BaseModel):
    instruction: str = Field(description="Game instruction for the child")
    narrative: str = Field(description="Story framing from the animal character")
    image_hint: Optional[str] = Field(
        None, description="Image object name for visual hint"
    )
    options: Optional[list[str]] = Field(None, description="Touch/select options")
    correct_answer: Optional[str] = Field(None, description="Expected correct answer")
    target_word: Optional[str] = Field(None, description="Word for speech tasks")
    interaction_type: str = Field(
        description="How child interacts: 'touch', 'voice', 'drag', 'tap'"
    )


class AssessmentActivityResponse(BaseModel):
    activity_index: int
    total_activities: int
    dimension: str
    level: int
    character: dict
    content: ActivityContent
    is_last: bool = False


# -- Assessment Response --


class AssessmentRespondRequest(BaseModel):
    activity_index: int
    selected_option: Optional[str] = Field(
        None, description="Selected option for touch tasks"
    )
    spoken_text: Optional[str] = Field(
        None, description="Transcribed speech for voice tasks"
    )
    response_time_ms: Optional[int] = Field(
        None, description="Time taken to respond in ms"
    )
    interaction_type: str = Field(default="touch", description="How child responded")


class AssessmentRespondResponse(BaseModel):
    is_correct: bool
    feedback: dict = Field(
        description="Character feedback (message, emoji, encouragement)"
    )
    should_continue: bool = True
    progress_fraction: float = Field(
        description="0.0 to 1.0 progress through assessment"
    )


# -- Assessment Complete --


class DimensionResult(BaseModel):
    dimension: str
    dimension_label: str
    assessed_level: int
    max_tested_level: int
    correct_count: int
    total_count: int
    accuracy: float
    icon: str
    color: str


class AssessmentCompleteResponse(BaseModel):
    assessment_id: str
    player_id: str
    dimensions: list[DimensionResult]
    overall_level: float
    total_activities: int
    total_correct: int
    duration_seconds: Optional[int] = None
    character_message: str = Field(
        description="Celebration message from the animal guide"
    )


# -- Assessment Results (same as complete but retrievable later) --


class AssessmentResultsResponse(BaseModel):
    assessment_id: str
    player_id: str
    dimensions: list[DimensionResult]
    overall_level: float
    completed: bool
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
