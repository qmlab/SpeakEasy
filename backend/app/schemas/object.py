from datetime import datetime
from typing import List, Optional
from enum import Enum
from pydantic import BaseModel, Field


class ImageType(str, Enum):
    FLASHCARD = "flashcard"
    FIND_OBJECT = "find_object"
    THUMBNAIL = "thumbnail"


class BoundingBoxCreate(BaseModel):
    x: float = Field(..., ge=0, le=1, description="X coordinate (0-1 normalized)")
    y: float = Field(..., ge=0, le=1, description="Y coordinate (0-1 normalized)")
    width: float = Field(..., ge=0, le=1, description="Width (0-1 normalized)")
    height: float = Field(..., ge=0, le=1, description="Height (0-1 normalized)")


class BoundingBoxResponse(BaseModel):
    id: str
    object_image_id: str
    x: float
    y: float
    width: float
    height: float
    created_at: datetime

    class Config:
        from_attributes = True


class ObjectImageCreate(BaseModel):
    image_url: str
    image_type: ImageType = ImageType.FLASHCARD
    bounding_boxes: Optional[List[BoundingBoxCreate]] = None


class ObjectImageResponse(BaseModel):
    id: str
    object_id: str
    image_url: str
    image_type: str
    created_at: datetime
    bounding_boxes: List[BoundingBoxResponse] = []

    class Config:
        from_attributes = True


class ObjectCreate(BaseModel):
    name: str
    category: str


class ObjectResponse(BaseModel):
    id: str
    name: str
    category: str
    created_at: datetime
    images: List[ObjectImageResponse] = []

    class Config:
        from_attributes = True


class ObjectListResponse(BaseModel):
    id: str
    name: str
    category: str
    image_count: int
    thumbnail_url: Optional[str] = None
    flashcard_url: Optional[str] = None

    class Config:
        from_attributes = True
