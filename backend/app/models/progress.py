import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Integer, Boolean
from sqlalchemy.orm import relationship
from app.database import Base


class PlayerProgress(Base):
    __tablename__ = "player_progress"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player_id = Column(String, ForeignKey("players.id"), nullable=False)
    object_id = Column(String, ForeignKey("objects.id"), nullable=False)
    last_rating = Column(Float, nullable=False, default=0.0)
    practice_count = Column(Integer, nullable=False, default=0)
    consecutive_failed_attempts = Column(Integer, nullable=False, default=0)
    is_learned = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    player = relationship("Player", back_populates="progress")
    object = relationship("Object", back_populates="progress")
