"""Pydantic schemas for AI personalization endpoints."""

from typing import Optional
from pydantic import BaseModel, Field


# -- Social Story --


class SocialStoryRequest(BaseModel):
    player_id: str
    scenario: Optional[str] = Field(
        None,
        description="Optional specific social scenario to address (e.g., 'sharing toys at school')",
    )
    language: str = Field("en", description="Language code: 'en' or 'zh'")


class SocialStoryResponse(BaseModel):
    player_id: str
    title: str
    story: str
    target_skill: str
    practice_tips: list[str]
    social_level: Optional[int] = None
    source: str = Field(description="'llm' or 'template'")


# -- Behavior Guidance --


class BehaviorGuidanceRequest(BaseModel):
    player_id: str
    dimension: Optional[str] = Field(
        None, description="Focus on a specific dimension, or omit for all"
    )
    concern: Optional[str] = Field(
        None, description="Optional specific concern from parent/therapist"
    )
    language: str = Field("en", description="Language code: 'en' or 'zh'")


class GuidanceRecommendation(BaseModel):
    dimension: str
    dimension_label: Optional[str] = None
    current_level: Optional[int] = None
    priority: str = Field(description="'high', 'medium', or 'low'")
    suggestions: list[str] = Field(description="List of actionable suggestions")
    rationale: Optional[str] = None


class BehaviorGuidanceResponse(BaseModel):
    player_id: str
    summary: str
    recommendations: list[GuidanceRecommendation]
    home_activities: list[str]
    source: str


# -- Progress Summary --


class ProgressSummaryRequest(BaseModel):
    player_id: str
    language: str = Field("en", description="Language code: 'en' or 'zh'")


class DimensionAnalysis(BaseModel):
    dimension: str
    dimension_label: str
    level: int
    current_ability: str
    next_skill: Optional[str] = None
    status: str


class ProgressStats(BaseModel):
    total_sessions: int
    total_attempts: int
    overall_accuracy: float


class ProgressSummaryResponse(BaseModel):
    player_id: str
    narrative: str
    strengths: list[str]
    areas_for_growth: list[str]
    next_steps: list[str]
    dimensions: list[DimensionAnalysis]
    stats: ProgressStats
    source: str


# -- Task Content Generation --


class TaskContentRequest(BaseModel):
    player_id: str
    dimension: str
    task_type: str
    interests: Optional[list[str]] = Field(
        None,
        description="Child's interests to personalize tasks (e.g., ['dinosaurs', 'trains'])",
    )
    language: str = Field("en", description="Language code: 'en' or 'zh'")
    count: int = Field(3, ge=1, le=10, description="Number of tasks to generate")


class GeneratedTask(BaseModel):
    instruction: str
    correct_answer: str
    options: list[str]
    image_hint: str
    difficulty_note: Optional[str] = None


class TaskContentResponse(BaseModel):
    player_id: str
    dimension: str
    task_type: str
    level: int
    tasks: list[GeneratedTask]
    source: str


# -- AI Status --


class AIStatusResponse(BaseModel):
    llm_enabled: bool
    model: Optional[str] = None
    base_url: Optional[str] = None
    fallback_mode: str
    supported_features: list[str]
