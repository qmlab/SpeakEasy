"""
Adaptive learning API routes.

Handles sessions, task selection, attempt processing, and profile management.
"""

import json
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.adaptive import DevelopmentalDimension
from app.models.player import Player
from app.schemas.adaptive import (
    StartSessionRequest,
    SessionResponse,
    NextTaskResponse,
    SubmitAttemptRequest,
    AttemptResultResponse,
    EndSessionResponse,
    FullProfileResponse,
    DevelopmentalProfileResponse,
    DevelopmentalProfileUpdate,
    ReinforcementConfigResponse,
    ReinforcementConfigUpdate,
    SpeechEvaluationRequest,
    SpeechEvaluationResponse,
    OpenEndedEvaluationRequest,
    OpenEndedEvaluationResponse,
    ModalityRecommendationResponse,
)
from app.services.adaptive_engine import AdaptiveEngine
from app.services.speech_evaluation import evaluate_open_ended, evaluate_speech

router = APIRouter(prefix="/adaptive", tags=["adaptive"])


def _validate_player(db: Session, player_id: str) -> Player:
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail=f"Player {player_id} not found")
    return player


@router.get("/profiles/{player_id}", response_model=FullProfileResponse)
def get_player_profiles(player_id: str, db: Session = Depends(get_db)):
    """Get all developmental profiles for a player."""
    player = _validate_player(db, player_id)
    engine = AdaptiveEngine(db)
    profiles = engine.get_or_create_profiles(player_id)

    levels = [p.level for p in profiles]
    overall = sum(levels) / len(levels) if levels else 0.0

    return FullProfileResponse(
        player_id=player_id,
        player_name=player.name,
        dimensions=[DevelopmentalProfileResponse.model_validate(p) for p in profiles],
        overall_level=round(overall, 2),
    )


@router.put(
    "/profiles/{player_id}/{dimension}", response_model=DevelopmentalProfileResponse
)
def update_player_profile(
    player_id: str,
    dimension: str,
    update: DevelopmentalProfileUpdate,
    db: Session = Depends(get_db),
):
    """Update a specific developmental profile dimension."""
    _validate_player(db, player_id)

    valid_dims = [d.value for d in DevelopmentalDimension]
    if dimension not in valid_dims:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid dimension: {dimension}. Valid: {valid_dims}",
        )

    engine = AdaptiveEngine(db)
    profile = engine.get_profile(player_id, dimension)
    if not profile:
        engine.get_or_create_profiles(player_id)
        profile = engine.get_profile(player_id, dimension)

    if update.level is not None:
        profile = engine.update_profile_level(player_id, dimension, update.level)
    if update.sub_scores is not None:
        profile.sub_scores = update.sub_scores
    if update.assessed is not None:
        profile.assessed = update.assessed

    db.commit()
    db.refresh(profile)
    return DevelopmentalProfileResponse.model_validate(profile)


@router.post("/sessions/start", response_model=SessionResponse)
def start_session(request: StartSessionRequest, db: Session = Depends(get_db)):
    """Start a new learning or assessment session."""
    _validate_player(db, request.player_id)

    if request.dimension:
        valid_dims = [d.value for d in DevelopmentalDimension]
        if request.dimension not in valid_dims:
            raise HTTPException(
                status_code=400, detail=f"Invalid dimension: {request.dimension}"
            )

    engine = AdaptiveEngine(db)
    session = engine.start_session(
        player_id=request.player_id,
        session_type=request.session_type,
        dimension=request.dimension,
    )
    return SessionResponse.model_validate(session)


@router.post("/sessions/{session_id}/end", response_model=EndSessionResponse)
def end_session(session_id: str, db: Session = Depends(get_db)):
    """End a learning session and get summary."""
    engine = AdaptiveEngine(db)
    try:
        session = engine.end_session(session_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    accuracy = (
        (session.correct_count / session.total_count)
        if session.total_count > 0
        else 0.0
    )

    # Calculate level change from session attempts
    level_change = 0  # Will be tracked in future iterations

    return EndSessionResponse(
        session_id=session.id,
        tasks_completed=session.tasks_completed,
        correct_count=session.correct_count,
        total_count=session.total_count,
        accuracy=round(accuracy, 3),
        avg_response_time_ms=session.avg_response_time_ms,
        level_change=level_change,
        rewards_earned=session.correct_count,  # Simplified for now
    )


@router.get("/sessions/{session_id}/next-task", response_model=NextTaskResponse)
def get_next_task(
    session_id: str,
    player_id: str,
    dimension: str,
    db: Session = Depends(get_db),
):
    """Get the next adaptive task for the current session."""
    _validate_player(db, player_id)

    valid_dims = [d.value for d in DevelopmentalDimension]
    if dimension not in valid_dims:
        raise HTTPException(status_code=400, detail=f"Invalid dimension: {dimension}")

    engine = AdaptiveEngine(db)
    result = engine.get_next_task(session_id, player_id, dimension)

    if not result:
        raise HTTPException(
            status_code=404,
            detail="No tasks available for this dimension and level. Please seed tasks first.",
        )

    return NextTaskResponse(**result)


@router.post("/attempts", response_model=AttemptResultResponse)
def submit_attempt(request: SubmitAttemptRequest, db: Session = Depends(get_db)):
    """Submit a task attempt and get adaptive feedback."""
    _validate_player(db, request.player_id)

    engine = AdaptiveEngine(db)
    try:
        result = engine.process_attempt(
            session_id=request.session_id,
            task_id=request.task_id,
            player_id=request.player_id,
            is_correct=request.is_correct,
            score=request.score,
            response_time_ms=request.response_time_ms,
            prompt_level=request.prompt_level,
            response_data=request.response_data,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    return AttemptResultResponse(**result)


@router.post("/assess/{player_id}/{dimension}")
def run_assessment(
    player_id: str,
    dimension: str,
    results: list[dict],
    db: Session = Depends(get_db),
):
    """Process assessment results and set initial level for a dimension."""
    _validate_player(db, player_id)

    valid_dims = [d.value for d in DevelopmentalDimension]
    if dimension not in valid_dims:
        raise HTTPException(status_code=400, detail=f"Invalid dimension: {dimension}")

    engine = AdaptiveEngine(db)
    result = engine.run_assessment(player_id, dimension, results)
    return result


@router.post("/evaluate-speech", response_model=SpeechEvaluationResponse)
def evaluate_speech_endpoint(request: SpeechEvaluationRequest):
    """Evaluate a spoken response against a target word/phrase."""
    result = evaluate_speech(
        target=request.target,
        spoken=request.spoken,
        accept_threshold=request.accept_threshold,
    )
    return SpeechEvaluationResponse(**result)


@router.post("/evaluate-open-ended", response_model=OpenEndedEvaluationResponse)
def evaluate_open_ended_endpoint(request: OpenEndedEvaluationRequest):
    """Evaluate an open-ended spoken response using AI.

    For questions like "What is your favorite animal?" where there is no
    single correct answer.  Uses LLM when available, falls back to keyword
    matching.
    """
    result = evaluate_open_ended(
        question=request.question,
        spoken=request.spoken,
        example_answers=request.example_answers,
        keywords=request.keywords,
    )
    return OpenEndedEvaluationResponse(**result)


@router.get("/modality/{player_id}", response_model=ModalityRecommendationResponse)
def get_recommended_modality(player_id: str, db: Session = Depends(get_db)):
    """Get recommended interaction modality for a player based on their profile."""
    _validate_player(db, player_id)
    engine = AdaptiveEngine(db)
    result = engine.recommend_modality(player_id)
    return ModalityRecommendationResponse(**result)


@router.get("/reinforcement/{player_id}", response_model=ReinforcementConfigResponse)
def get_reinforcement_config(player_id: str, db: Session = Depends(get_db)):
    """Get reinforcement/ABA config for a player."""
    _validate_player(db, player_id)
    engine = AdaptiveEngine(db)
    config = engine._get_reinforcement_config(player_id)
    return ReinforcementConfigResponse.model_validate(config)


@router.put("/reinforcement/{player_id}", response_model=ReinforcementConfigResponse)
def update_reinforcement_config(
    player_id: str,
    update: ReinforcementConfigUpdate,
    db: Session = Depends(get_db),
):
    """Update reinforcement/ABA config for a player."""
    _validate_player(db, player_id)
    engine = AdaptiveEngine(db)
    config = engine._get_reinforcement_config(player_id)

    if update.reward_frequency is not None:
        config.reward_frequency = update.reward_frequency
    if update.reward_type is not None:
        config.reward_type = update.reward_type
    if update.prompt_strategy is not None:
        config.prompt_strategy = update.prompt_strategy
    if update.confidence_rebuild_threshold is not None:
        config.confidence_rebuild_threshold = update.confidence_rebuild_threshold
    if update.session_max_duration_minutes is not None:
        config.session_max_duration_minutes = update.session_max_duration_minutes
    if update.break_after_minutes is not None:
        config.break_after_minutes = update.break_after_minutes

    db.commit()
    db.refresh(config)
    return ReinforcementConfigResponse.model_validate(config)


# ---- Photo URLs ----

_photo_urls_path = (
    Path(__file__).parent.parent / "resources" / "images" / "photo_urls.json"
)
_photo_urls_cache: dict[str, str] | None = None


def _load_photo_urls() -> dict[str, str]:
    global _photo_urls_cache
    if _photo_urls_cache is not None:
        return _photo_urls_cache
    if _photo_urls_path.exists():
        data = json.loads(_photo_urls_path.read_text())
        _photo_urls_cache = data.get("photos", {})
    else:
        _photo_urls_cache = {}
    return _photo_urls_cache


@router.get("/photo-urls")
def get_photo_urls():
    """Return the full mapping of object names to real photo URLs."""
    return {"photos": _load_photo_urls()}


# ---- AI Fuzzy Answer Matching ----


@router.post("/evaluate-answer")
def evaluate_answer_fuzzy(request: dict):
    """AI-powered fuzzy answer matching for non-object-cognition tasks.

    Accepts answers that are semantically close to the correct answer,
    even if not an exact string match. Designed for young children who
    may give approximate or partial answers.
    """
    question = request.get("question", "")
    given_answer = request.get("given_answer", "")
    correct_answer = request.get("correct_answer", "")
    dimension = request.get("dimension", "")

    if not given_answer or not correct_answer:
        return {"is_accepted": False, "score": 0.0, "feedback": "no_response"}

    # For object_cognition, use strict matching
    if dimension == "object_cognition":
        is_correct = given_answer.strip().lower() == correct_answer.strip().lower()
        return {
            "is_accepted": is_correct,
            "score": 1.0 if is_correct else 0.0,
            "feedback": "correct" if is_correct else "incorrect",
        }

    # For other dimensions, use lenient AI evaluation
    # strict_mode=True skips the catch-all "any meaningful word" fallback
    result = evaluate_open_ended(
        question=question or f"Select the correct answer: {correct_answer}",
        spoken=given_answer,
        example_answers=[correct_answer],
        keywords=[
            w
            for w in correct_answer.lower().split()[:5]
            if w
            not in {
                "the",
                "a",
                "an",
                "is",
                "am",
                "are",
                "was",
                "were",
                "in",
                "on",
                "at",
                "to",
                "of",
                "and",
                "or",
                "it",
                "i",
            }
        ][:3]
        or [correct_answer.lower().strip().split()[0]]
        if correct_answer.strip()
        else [],
        strict_mode=True,
    )

    return result
