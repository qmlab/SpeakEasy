import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Enum
from sqlalchemy.orm import relationship
import enum
from app.database import Base


class ImageType(str, enum.Enum):
    FLASHCARD = "flashcard"
    FIND_OBJECT = "find_object"
    THUMBNAIL = "thumbnail"


class Object(Base):
    __tablename__ = "objects"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False, unique=True)
    category = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    images = relationship("ObjectImage", back_populates="object", cascade="all, delete-orphan")
    attempts = relationship("AttemptHistory", back_populates="object")


class ObjectImage(Base):
    __tablename__ = "object_images"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    object_id = Column(String, ForeignKey("objects.id"), nullable=False)
    image_url = Column(String, nullable=False)
    image_type = Column(String, nullable=False, default=ImageType.FLASHCARD.value)
    created_at = Column(DateTime, default=datetime.utcnow)

    object = relationship("Object", back_populates="images")
    bounding_boxes = relationship("BoundingBox", back_populates="object_image", cascade="all, delete-orphan")


class BoundingBox(Base):
    __tablename__ = "bounding_boxes"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    object_image_id = Column(String, ForeignKey("object_images.id"), nullable=False)
    x = Column(Float, nullable=False)
    y = Column(Float, nullable=False)
    width = Column(Float, nullable=False)
    height = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    object_image = relationship("ObjectImage", back_populates="bounding_boxes")
