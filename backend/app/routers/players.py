from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models import Player, AttemptHistory
from app.schemas.player import PlayerCreate, PlayerResponse, PlayerStats
from app.schemas.attempt import AttemptResponse

router = APIRouter(prefix="/players", tags=["players"])


@router.post("/", response_model=PlayerResponse)
def create_player(player: PlayerCreate, db: Session = Depends(get_db)):
    db_player = Player(name=player.name)
    db.add(db_player)
    db.commit()
    db.refresh(db_player)
    return db_player


@router.get("/", response_model=List[PlayerResponse])
def list_players(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    players = db.query(Player).offset(skip).limit(limit).all()
    return players


@router.get("/{player_id}", response_model=PlayerResponse)
def get_player(player_id: str, db: Session = Depends(get_db)):
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    return player


@router.get("/{player_id}/history", response_model=List[AttemptResponse])
def get_player_history(
    player_id: str,
    feature_type: int = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    query = db.query(AttemptHistory).filter(AttemptHistory.player_id == player_id)
    
    if feature_type is not None:
        query = query.filter(AttemptHistory.feature_type == feature_type)
    
    attempts = query.order_by(AttemptHistory.created_at.desc()).offset(skip).limit(limit).all()
    return attempts


@router.get("/{player_id}/stats", response_model=PlayerStats)
def get_player_stats(player_id: str, db: Session = Depends(get_db)):
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    attempts = db.query(AttemptHistory).filter(AttemptHistory.player_id == player_id).all()
    
    total_attempts = len(attempts)
    correct_attempts = sum(1 for a in attempts if a.is_correct)
    
    say_word_attempts = [a for a in attempts if a.feature_type == 1]
    find_object_attempts = [a for a in attempts if a.feature_type == 2]
    
    say_word_correct = sum(1 for a in say_word_attempts if a.is_correct)
    find_object_correct = sum(1 for a in find_object_attempts if a.is_correct)
    
    total_score = sum(a.score for a in attempts)
    average_score = total_score / total_attempts if total_attempts > 0 else 0
    accuracy_percentage = (correct_attempts / total_attempts * 100) if total_attempts > 0 else 0
    
    return PlayerStats(
        player_id=player_id,
        player_name=player.name,
        total_attempts=total_attempts,
        correct_attempts=correct_attempts,
        accuracy_percentage=round(accuracy_percentage, 2),
        say_word_attempts=len(say_word_attempts),
        say_word_correct=say_word_correct,
        find_object_attempts=len(find_object_attempts),
        find_object_correct=find_object_correct,
        average_score=round(average_score, 2)
    )


@router.delete("/{player_id}")
def delete_player(player_id: str, db: Session = Depends(get_db)):
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    db.delete(player)
    db.commit()
    return {"message": "Player deleted successfully"}
