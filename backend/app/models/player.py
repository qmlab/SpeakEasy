import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from app.database import Base


class Player(Base):
    __tablename__ = "players"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    apple_user_id = Column(String, unique=True, nullable=True, index=True)
    device_id = Column(String, unique=True, nullable=True, index=True)
    email = Column(String, nullable=True)
    is_guest = Column(String, default="false")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    attempts = relationship("AttemptHistory", back_populates="player")
    progress = relationship("PlayerProgress", back_populates="player")
