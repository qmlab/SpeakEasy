"""
Story-based assessment API routes.

Provides an interactive story flow where assessment questions are embedded
within a narrative. The child experiences a story (e.g. Bunny's Birthday
Party) and answers questions that naturally arise from the plot.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.player import Player
from app.schemas.story import (
    StoryListResponse,
    StoryInfo,
    StoryStartRequest,
    StoryStartResponse,
    SceneResponse,
    SceneRespondRequest,
    SceneRespondResponse,
    StoryCompleteResponse,
)
from app.services.story_engine import StoryEngine, list_available_stories

router = APIRouter(prefix="/story", tags=["story"])


def _validate_player(db: Session, player_id: str) -> Player:
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")
    return player


@router.get("/list", response_model=StoryListResponse)
def get_stories():
    """List all available story-based assessments."""
    stories = list_available_stories()
    return StoryListResponse(stories=[StoryInfo(**s) for s in stories])


@router.post("/start/{player_id}", response_model=StoryStartResponse)
def start_story(
    player_id: str,
    request: StoryStartRequest,
    db: Session = Depends(get_db),
):
    """Start a story-based assessment for a player."""
    _validate_player(db, player_id)
    engine = StoryEngine(db)
    try:
        result = engine.start_story(player_id, request.story_id)
    except (ValueError, FileNotFoundError) as e:
        raise HTTPException(status_code=404, detail=str(e))
    return StoryStartResponse(**result)


@router.get("/{assessment_id}/next-scene", response_model=SceneResponse)
def get_next_scene(assessment_id: str, db: Session = Depends(get_db)):
    """Get the next scene in the story."""
    engine = StoryEngine(db)
    try:
        result = engine.get_next_scene(assessment_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    if not result:
        raise HTTPException(
            status_code=404,
            detail="No more scenes. Call /complete to finish the story.",
        )

    return SceneResponse(**result)


@router.post("/{assessment_id}/respond", response_model=SceneRespondResponse)
def respond_to_scene(
    assessment_id: str,
    request: SceneRespondRequest,
    db: Session = Depends(get_db),
):
    """Submit the child's response to a story scene."""
    engine = StoryEngine(db)
    try:
        result = engine.process_response(
            assessment_id=assessment_id,
            scene_index=request.scene_index,
            selected_option=request.selected_option,
            spoken_text=request.spoken_text,
            response_time_ms=request.response_time_ms,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return SceneRespondResponse(**result)


@router.post("/{assessment_id}/complete", response_model=StoryCompleteResponse)
def complete_story(assessment_id: str, db: Session = Depends(get_db)):
    """Complete the story and update developmental profiles."""
    engine = StoryEngine(db)
    try:
        result = engine.complete_story(assessment_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    return StoryCompleteResponse(**result)
