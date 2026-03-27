import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Integer, Boolean, JSON, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class DevelopmentalDimension(str, enum.Enum):
    OBJECT_COGNITION = "object_cognition"
    LANGUAGE_EXPRESSION = "language_expression"
    LANGUAGE_COMPREHENSION = "language_comprehension"
    LITERACY = "literacy"
    SOCIAL_BEHAVIOR = "social_behavior"
    COGNITIVE_LOGIC = "cognitive_logic"


class SessionType(str, enum.Enum):
    ASSESSMENT = "assessment"
    PRACTICE = "practice"
    FREE_PLAY = "free_play"


class SessionStatus(str, enum.Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class TaskType(str, enum.Enum):
    MATCH = "match"
    IDENTIFY = "identify"
    CLASSIFY = "classify"
    FUNCTION = "function"
    ABSTRACT = "abstract"
    SAY_WORD = "say_word"
    FIND_OBJECT = "find_object"


class Modality(str, enum.Enum):
    TOUCH = "touch"
    IMAGE_EXCHANGE = "image_exchange"
    VOICE = "voice"
    TEXT = "text"


class PromptLevel(int, enum.Enum):
    INDEPENDENT = 0
    PARTIAL = 1
    FULL = 2


class PromptStrategy(str, enum.Enum):
    GRADUATED_GUIDANCE = "graduated_guidance"
    MOST_TO_LEAST = "most_to_least"
    LEAST_TO_MOST = "least_to_most"


class RewardType(str, enum.Enum):
    ANIMATION = "animation"
    SOUND = "sound"
    POINTS = "points"
    STICKER = "sticker"


class DevelopmentalProfile(Base):
    __tablename__ = "developmental_profiles"
    __table_args__ = (
        UniqueConstraint("player_id", "dimension", name="uq_player_dimension"),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player_id = Column(String, ForeignKey("players.id"), nullable=False, index=True)
    dimension = Column(String, nullable=False)
    level = Column(Integer, nullable=False, default=0)
    sub_scores = Column(JSON, nullable=True, default=dict)
    assessed = Column(Boolean, nullable=False, default=False)
    last_assessed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    player = relationship("Player", back_populates="profiles")


class LearningSession(Base):
    __tablename__ = "learning_sessions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player_id = Column(String, ForeignKey("players.id"), nullable=False, index=True)
    session_type = Column(String, nullable=False)
    dimension = Column(String, nullable=True)
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)
    tasks_completed = Column(Integer, nullable=False, default=0)
    correct_count = Column(Integer, nullable=False, default=0)
    total_count = Column(Integer, nullable=False, default=0)
    avg_response_time_ms = Column(Float, nullable=True)
    prompt_dependency_rate = Column(Float, nullable=True)
    engagement_score = Column(Float, nullable=True)
    status = Column(String, nullable=False, default=SessionStatus.ACTIVE.value)
    current_level = Column(Integer, nullable=False, default=0)

    player = relationship("Player", back_populates="learning_sessions")
    task_attempts = relationship("TaskAttempt", back_populates="session", cascade="all, delete-orphan")


class AdaptiveTask(Base):
    __tablename__ = "adaptive_tasks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    dimension = Column(String, nullable=False, index=True)
    level = Column(Integer, nullable=False, index=True)
    task_type = Column(String, nullable=False)
    modalities = Column(JSON, nullable=False, default=list)
    content = Column(JSON, nullable=False)
    metadata_info = Column(JSON, nullable=True, default=dict)
    is_assessment = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    task_attempts = relationship("TaskAttempt", back_populates="task")


class TaskAttempt(Base):
    __tablename__ = "task_attempts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("learning_sessions.id"), nullable=False, index=True)
    task_id = Column(String, ForeignKey("adaptive_tasks.id"), nullable=True)
    player_id = Column(String, ForeignKey("players.id"), nullable=False, index=True)
    response_time_ms = Column(Integer, nullable=True)
    prompt_level = Column(Integer, nullable=False, default=PromptLevel.INDEPENDENT.value)
    is_correct = Column(Boolean, nullable=False, default=False)
    score = Column(Integer, nullable=False, default=0)
    response_data = Column(JSON, nullable=True, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("LearningSession", back_populates="task_attempts")
    task = relationship("AdaptiveTask", back_populates="task_attempts")
    player = relationship("Player", back_populates="task_attempts")


class ReinforcementConfig(Base):
    __tablename__ = "reinforcement_configs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player_id = Column(String, ForeignKey("players.id"), nullable=False, unique=True, index=True)
    reward_frequency = Column(Integer, nullable=False, default=3)
    reward_type = Column(String, nullable=False, default=RewardType.ANIMATION.value)
    prompt_strategy = Column(String, nullable=False, default=PromptStrategy.MOST_TO_LEAST.value)
    confidence_rebuild_threshold = Column(Integer, nullable=False, default=3)
    session_max_duration_minutes = Column(Integer, nullable=False, default=15)
    break_after_minutes = Column(Integer, nullable=False, default=10)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    player = relationship("Player", back_populates="reinforcement_config")
