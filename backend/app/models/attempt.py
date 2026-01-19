import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Integer, Boolean
from sqlalchemy.orm import relationship
from app.database import Base


class AttemptHistory(Base):
    __tablename__ = "attempt_history"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player_id = Column(String, ForeignKey("players.id"), nullable=False)
    object_id = Column(String, ForeignKey("objects.id"), nullable=False)
    feature_type = Column(Integer, nullable=False)
    score = Column(Integer, nullable=False, default=0)
    spoken_text = Column(String, nullable=True)
    tap_x = Column(Float, nullable=True)
    tap_y = Column(Float, nullable=True)
    is_correct = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    player = relationship("Player", back_populates="attempts")
    object = relationship("Object", back_populates="attempts")
