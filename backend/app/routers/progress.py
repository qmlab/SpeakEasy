from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models.progress import PlayerProgress
from app.models.player import Player
from app.models.object import Object
from app.schemas.progress import (
    ProgressResponse,
    RecordProgressRequest,
    RecordProgressResponse,
    ProgressSummary,
)

router = APIRouter(prefix="/progress", tags=["progress"])


def get_or_create_player(db: Session, player_id: str) -> Player:
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        player = Player(id=player_id, name=f"Player_{player_id[:8]}")
        db.add(player)
        db.commit()
        db.refresh(player)
    return player


@router.post("/record", response_model=RecordProgressResponse)
def record_progress(request: RecordProgressRequest, db: Session = Depends(get_db)):
    get_or_create_player(db, request.player_id)
    
    obj = db.query(Object).filter(Object.id == request.object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail=f"Object {request.object_id} not found")
    
    progress = db.query(PlayerProgress).filter(
        PlayerProgress.player_id == request.player_id,
        PlayerProgress.object_id == request.object_id
    ).first()
    
    if not progress:
        progress = PlayerProgress(
            player_id=request.player_id,
            object_id=request.object_id,
            last_rating=0.0,
            practice_count=0,
            consecutive_failed_attempts=0,
            is_learned=False
        )
        db.add(progress)
    
    progress.last_rating = request.rating
    progress.practice_count += 1
    
    if request.rating >= 4.0:
        progress.consecutive_failed_attempts = 0
        if not progress.is_learned:
            progress.is_learned = True
            message = "Congratulations! You learned this word!"
        else:
            message = "Great job! Keep it up!"
    else:
        progress.consecutive_failed_attempts += 1
        if progress.consecutive_failed_attempts >= 3:
            message = "Let me help you practice this word."
        else:
            message = "Keep trying! You're doing great!"
    
    db.commit()
    db.refresh(progress)
    
    return RecordProgressResponse(
        success=True,
        is_learned=progress.is_learned,
        last_rating=progress.last_rating,
        practice_count=progress.practice_count,
        consecutive_failed_attempts=progress.consecutive_failed_attempts,
        message=message
    )


@router.get("/{player_id}", response_model=List[ProgressResponse])
def get_player_progress(player_id: str, db: Session = Depends(get_db)):
    progress_list = db.query(PlayerProgress).filter(
        PlayerProgress.player_id == player_id
    ).all()
    return progress_list


@router.get("/{player_id}/{object_id}", response_model=Optional[ProgressResponse])
def get_object_progress(player_id: str, object_id: str, db: Session = Depends(get_db)):
    progress = db.query(PlayerProgress).filter(
        PlayerProgress.player_id == player_id,
        PlayerProgress.object_id == object_id
    ).first()
    return progress


@router.get("/{player_id}/summary", response_model=ProgressSummary)
def get_progress_summary(player_id: str, db: Session = Depends(get_db)):
    progress_list = db.query(PlayerProgress).filter(
        PlayerProgress.player_id == player_id
    ).all()
    
    total_learned = sum(1 for p in progress_list if p.is_learned)
    total_stars = total_learned
    
    progress_by_object = {p.object_id: p for p in progress_list}
    
    return ProgressSummary(
        player_id=player_id,
        total_learned=total_learned,
        total_stars=total_stars,
        progress_by_object=progress_by_object
    )


@router.delete("/{player_id}")
def reset_player_progress(player_id: str, db: Session = Depends(get_db)):
    db.query(PlayerProgress).filter(
        PlayerProgress.player_id == player_id
    ).delete()
    db.commit()
    return {"success": True, "message": "Progress reset successfully"}
