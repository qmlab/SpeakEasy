"""
Dashboard API routes for parents and therapists.

Provides progress summaries, dimension-specific progress, and session history.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.adaptive import DevelopmentalDimension, LearningSession
from app.models.player import Player
from app.schemas.adaptive import (
    DashboardSummary,
    DimensionProgress,
    SessionResponse,
    DevelopmentalProfileResponse,
)
from app.services.adaptive_engine import AdaptiveEngine

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/{player_id}/summary", response_model=DashboardSummary)
def get_dashboard_summary(player_id: str, db: Session = Depends(get_db)):
    """Get comprehensive dashboard summary for a player."""
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")

    engine = AdaptiveEngine(db)
    summary = engine.get_dashboard_summary(player_id)

    return DashboardSummary(
        player_id=summary["player_id"],
        player_name=summary["player_name"],
        dimensions=[DevelopmentalProfileResponse.model_validate(p) for p in summary["dimensions"]],
        recent_sessions=[SessionResponse.model_validate(s) for s in summary["recent_sessions"]],
        total_sessions=summary["total_sessions"],
        total_tasks_completed=summary["total_tasks_completed"],
        overall_accuracy=summary["overall_accuracy"],
        streak_days=summary["streak_days"],
        mastered_tasks=summary["mastered_tasks"],
        struggling_tasks=summary["struggling_tasks"],
    )


@router.get("/{player_id}/dimensions/{dimension}", response_model=DimensionProgress)
def get_dimension_progress(
    player_id: str,
    dimension: str,
    db: Session = Depends(get_db),
):
    """Get detailed progress for a specific developmental dimension."""
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")

    valid_dims = [d.value for d in DevelopmentalDimension]
    if dimension not in valid_dims:
        raise HTTPException(status_code=400, detail=f"Invalid dimension: {dimension}. Valid: {valid_dims}")

    engine = AdaptiveEngine(db)
    progress = engine.get_dimension_progress(player_id, dimension)

    return DimensionProgress(**progress)


@router.get("/{player_id}/sessions", response_model=list[SessionResponse])
def get_session_history(
    player_id: str,
    limit: int = 20,
    offset: int = 0,
    dimension: str = None,
    db: Session = Depends(get_db),
):
    """Get session history for a player."""
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")

    query = (
        db.query(LearningSession)
        .filter(LearningSession.player_id == player_id)
        .order_by(desc(LearningSession.started_at))
    )

    if dimension:
        valid_dims = [d.value for d in DevelopmentalDimension]
        if dimension not in valid_dims:
            raise HTTPException(status_code=400, detail=f"Invalid dimension: {dimension}")
        query = query.filter(LearningSession.dimension == dimension)

    sessions = query.offset(offset).limit(limit).all()
    return [SessionResponse.model_validate(s) for s in sessions]
