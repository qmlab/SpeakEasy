"""
AI Personalization API routes for Rising Star Kid.

Provides LLM-powered (with template fallback) endpoints for:
- Social story generation
- Behavior guidance for parents/therapists
- Natural-language progress summaries
- Personalized task content generation
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.player import Player
from app.schemas.ai import (
    SocialStoryRequest,
    SocialStoryResponse,
    BehaviorGuidanceRequest,
    BehaviorGuidanceResponse,
    ProgressSummaryRequest,
    ProgressSummaryResponse,
    TaskContentRequest,
    TaskContentResponse,
    AIStatusResponse,
)
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["ai"])


def _validate_player(player_id: str, db: Session) -> None:
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")


@router.get("/status", response_model=AIStatusResponse)
def get_ai_status(db: Session = Depends(get_db)):
    """Get current AI configuration status."""
    service = AIService(db)
    return service.get_ai_status()


@router.post("/social-story", response_model=SocialStoryResponse)
def generate_social_story(
    request: SocialStoryRequest,
    db: Session = Depends(get_db),
):
    """Generate a personalized social story for a child.

    Uses LLM when OPENAI_API_KEY is configured, otherwise falls back
    to curated templates matched to the child's social behavior level.
    """
    _validate_player(request.player_id, db)
    service = AIService(db)
    try:
        result = service.generate_social_story(
            player_id=request.player_id,
            scenario=request.scenario,
            language=request.language,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/behavior-guidance", response_model=BehaviorGuidanceResponse)
def generate_behavior_guidance(
    request: BehaviorGuidanceRequest,
    db: Session = Depends(get_db),
):
    """Generate behavior guidance for parents and therapists.

    Provides evidence-based recommendations, home activities,
    and prioritized suggestions per dimension.
    """
    _validate_player(request.player_id, db)
    service = AIService(db)
    try:
        result = service.generate_behavior_guidance(
            player_id=request.player_id,
            dimension=request.dimension,
            concern=request.concern,
            language=request.language,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/progress-summary", response_model=ProgressSummaryResponse)
def generate_progress_summary(
    request: ProgressSummaryRequest,
    db: Session = Depends(get_db),
):
    """Generate a natural-language progress summary for parents/therapists.

    Includes narrative description, strengths, areas for growth,
    next steps, and per-dimension analysis.
    """
    _validate_player(request.player_id, db)
    service = AIService(db)
    try:
        result = service.generate_progress_summary(
            player_id=request.player_id,
            language=request.language,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/generate-tasks", response_model=TaskContentResponse)
def generate_task_content(
    request: TaskContentRequest,
    db: Session = Depends(get_db),
):
    """Generate personalized task content based on child's profile and interests.

    Creates task content JSON tailored to the child's current level,
    dimension, and personal interests for maximum engagement.
    """
    _validate_player(request.player_id, db)
    service = AIService(db)
    try:
        result = service.generate_task_content(
            player_id=request.player_id,
            dimension=request.dimension,
            task_type=request.task_type,
            interests=request.interests,
            language=request.language,
            count=request.count,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
