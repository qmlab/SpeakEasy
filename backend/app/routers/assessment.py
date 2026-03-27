"""
Assessment API routes - Gamified initial assessment.

Provides a game-like assessment flow where an animal character guides
the child through activities that evaluate all 6 developmental dimensions.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.player import Player
from app.schemas.assessment import (
    AssessmentStartResponse,
    AssessmentActivityResponse,
    AssessmentRespondRequest,
    AssessmentRespondResponse,
    AssessmentCompleteResponse,
    AssessmentResultsResponse,
)
from app.services.assessment_engine import AssessmentEngine

router = APIRouter(prefix="/assessment", tags=["assessment"])


def _validate_player(db: Session, player_id: str) -> Player:
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")
    return player


@router.post("/start/{player_id}", response_model=AssessmentStartResponse)
def start_assessment(player_id: str, db: Session = Depends(get_db)):
    """Start a new gamified assessment game for a player."""
    _validate_player(db, player_id)
    engine = AssessmentEngine(db)
    try:
        result = engine.start_assessment(player_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return AssessmentStartResponse(**result)


@router.get("/{assessment_id}/next-activity", response_model=AssessmentActivityResponse)
def get_next_activity(assessment_id: str, db: Session = Depends(get_db)):
    """Get the next game activity in the assessment."""
    engine = AssessmentEngine(db)
    try:
        result = engine.get_next_activity(assessment_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    if not result:
        raise HTTPException(
            status_code=404,
            detail="No more activities. Call /complete to finish the assessment.",
        )

    return AssessmentActivityResponse(**result)


@router.post("/{assessment_id}/respond", response_model=AssessmentRespondResponse)
def respond_to_activity(
    assessment_id: str,
    request: AssessmentRespondRequest,
    db: Session = Depends(get_db),
):
    """Submit a child's response to an assessment activity."""
    engine = AssessmentEngine(db)
    try:
        result = engine.process_response(
            assessment_id=assessment_id,
            activity_index=request.activity_index,
            selected_option=request.selected_option,
            spoken_text=request.spoken_text,
            response_time_ms=request.response_time_ms,
            interaction_type=request.interaction_type,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return AssessmentRespondResponse(**result)


@router.post("/{assessment_id}/complete", response_model=AssessmentCompleteResponse)
def complete_assessment(assessment_id: str, db: Session = Depends(get_db)):
    """Complete the assessment and generate developmental profile."""
    engine = AssessmentEngine(db)
    try:
        result = engine.complete_assessment(assessment_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    return AssessmentCompleteResponse(**result)


@router.get("/{assessment_id}/results", response_model=AssessmentResultsResponse)
def get_assessment_results(assessment_id: str, db: Session = Depends(get_db)):
    """Get results for an in-progress or recently completed assessment."""
    engine = AssessmentEngine(db)
    result = engine.get_results(assessment_id)

    if not result:
        raise HTTPException(
            status_code=404,
            detail="Assessment not found or already completed and cleaned up.",
        )

    return AssessmentResultsResponse(**result)
