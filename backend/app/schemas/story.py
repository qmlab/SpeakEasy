"""Pydantic schemas for story-based assessment endpoints."""

from typing import Optional
from pydantic import BaseModel, Field


# -- Story List --


class StoryInfo(BaseModel):
    story_id: str
    title: str
    title_zh: str
    character: str
    character_emoji: str
    estimated_minutes: int
    scene_count: int
    image_url: str = ""


class StoryListResponse(BaseModel):
    stories: list[StoryInfo]


# -- Story Start --


class StoryStartRequest(BaseModel):
    story_id: str = Field(description="ID of the story to start")


class StoryStartResponse(BaseModel):
    assessment_id: str
    story_id: str
    player_id: str
    title: str
    title_zh: str
    character: dict
    intro_narration: str
    intro_narration_zh: str
    intro_image_url: str = ""
    total_scenes: int


# -- Scene --


class SceneTest(BaseModel):
    instruction: str
    instruction_zh: str
    options: list[str] = []
    options_zh: list[str] = []
    correct_answer: str
    modality: str = "touch"
    dimension: str
    level: int
    image_hints: list[str] = []


class SceneResponse(BaseModel):
    scene_index: int
    total_scenes: int
    scene_id: str
    narration: str
    narration_zh: str
    image_url: str = ""
    test: SceneTest
    is_fallback: bool = False
    is_last: bool = False
    character: dict
    progress: float = 0.0


# -- Scene Response --


class SceneRespondRequest(BaseModel):
    scene_index: int
    selected_option: Optional[str] = None
    spoken_text: Optional[str] = None
    response_time_ms: Optional[int] = None


class SceneRespondResponse(BaseModel):
    is_correct: bool
    feedback: str
    feedback_zh: str
    should_continue: bool = True
    progress: float = 0.0


# -- Story Complete --


class StoryDimensionResult(BaseModel):
    dimension: str
    assessed_level: int
    correct_count: int
    total_count: int
    accuracy: float


class StoryCompleteResponse(BaseModel):
    assessment_id: str
    story_id: str
    player_id: str
    dimensions: list[StoryDimensionResult]
    total_correct: int
    total_tested: int
    overall_accuracy: float
    character: dict
    outro_narration: str
    outro_narration_zh: str
    outro_image_url: str = ""
