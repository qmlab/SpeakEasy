from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
import os
import uuid
import aiofiles

from app.database import get_db
from app.models import Object, ObjectImage, BoundingBox
from app.models.object import ImageType as ModelImageType
from app.schemas.object import (
    ObjectCreate, ObjectResponse, ObjectImageCreate, ObjectImageResponse,
    BoundingBoxCreate, BoundingBoxResponse, ObjectListResponse, ImageType
)
from app.services import cloudinary_service

router = APIRouter(prefix="/objects", tags=["objects"])

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")


@router.post("/", response_model=ObjectResponse)
def create_object(obj: ObjectCreate, db: Session = Depends(get_db)):
    existing = db.query(Object).filter(Object.name == obj.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Object with this name already exists")
    
    db_object = Object(name=obj.name, category=obj.category)
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


@router.get("/", response_model=List[ObjectListResponse])
def list_objects(
    category: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    query = db.query(Object)
    
    if category:
        query = query.filter(Object.category == category)
    
    objects = query.offset(skip).limit(limit).all()
    
    result = []
    for obj in objects:
        result.append(ObjectListResponse(
            id=obj.id,
            name=obj.name,
            category=obj.category,
            image_count=len(obj.images)
        ))
    
    return result


@router.get("/categories")
def list_categories(db: Session = Depends(get_db)):
    categories = db.query(Object.category).distinct().all()
    return [c[0] for c in categories]


@router.get("/{object_id}", response_model=ObjectResponse)
def get_object(object_id: str, db: Session = Depends(get_db)):
    obj = db.query(Object).filter(Object.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    return obj


@router.delete("/{object_id}")
def delete_object(object_id: str, db: Session = Depends(get_db)):
    obj = db.query(Object).filter(Object.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    
    db.delete(obj)
    db.commit()
    return {"message": "Object deleted successfully"}


@router.post("/{object_id}/images", response_model=ObjectImageResponse)
def add_object_image(
    object_id: str,
    image_data: ObjectImageCreate,
    db: Session = Depends(get_db)
):
    obj = db.query(Object).filter(Object.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    
    db_image = ObjectImage(
        object_id=object_id,
        image_url=image_data.image_url,
        image_type=image_data.image_type.value
    )
    db.add(db_image)
    db.commit()
    db.refresh(db_image)
    
    if image_data.bounding_boxes:
        for box in image_data.bounding_boxes:
            db_box = BoundingBox(
                object_image_id=db_image.id,
                x=box.x,
                y=box.y,
                width=box.width,
                height=box.height
            )
            db.add(db_box)
        db.commit()
        db.refresh(db_image)
    
    return db_image


@router.get("/{object_id}/images", response_model=List[ObjectImageResponse])
def get_object_images(
    object_id: str,
    image_type: Optional[ImageType] = Query(None, description="Filter by image type"),
    db: Session = Depends(get_db)
):
    obj = db.query(Object).filter(Object.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    
    query = db.query(ObjectImage).filter(ObjectImage.object_id == object_id)
    
    if image_type:
        query = query.filter(ObjectImage.image_type == image_type.value)
    
    return query.all()


@router.post("/{object_id}/images/upload", response_model=ObjectImageResponse)
async def upload_object_image(
    object_id: str,
    file: UploadFile = File(...),
    image_type: ImageType = Query(ImageType.FLASHCARD, description="Type of image"),
    db: Session = Depends(get_db)
):
    obj = db.query(Object).filter(Object.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    
    content = await file.read()
    
    if cloudinary_service.is_configured:
        folder = f"speakeasy/{obj.category}/{image_type.value}"
        public_id = f"{obj.name.lower().replace(' ', '_')}_{uuid.uuid4().hex[:8]}"
        
        try:
            result = cloudinary_service.upload_image(
                file_data=content,
                folder=folder,
                public_id=public_id
            )
            image_url = result["url"]
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to upload to Cloudinary: {str(e)}")
    else:
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        file_ext = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
        file_name = f"{uuid.uuid4()}{file_ext}"
        file_path = os.path.join(UPLOAD_DIR, file_name)
        
        async with aiofiles.open(file_path, "wb") as f:
            await f.write(content)
        
        image_url = f"/uploads/{file_name}"
    
    db_image = ObjectImage(
        object_id=object_id,
        image_url=image_url,
        image_type=image_type.value
    )
    db.add(db_image)
    db.commit()
    db.refresh(db_image)
    
    return db_image


@router.get("/images/{image_id}", response_model=ObjectImageResponse)
def get_object_image(image_id: str, db: Session = Depends(get_db)):
    image = db.query(ObjectImage).filter(ObjectImage.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    return image


@router.delete("/images/{image_id}")
def delete_object_image(image_id: str, db: Session = Depends(get_db)):
    image = db.query(ObjectImage).filter(ObjectImage.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    db.delete(image)
    db.commit()
    return {"message": "Image deleted successfully"}


@router.post("/images/{image_id}/bounding-boxes", response_model=BoundingBoxResponse)
def add_bounding_box(
    image_id: str,
    box: BoundingBoxCreate,
    db: Session = Depends(get_db)
):
    image = db.query(ObjectImage).filter(ObjectImage.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    db_box = BoundingBox(
        object_image_id=image_id,
        x=box.x,
        y=box.y,
        width=box.width,
        height=box.height
    )
    db.add(db_box)
    db.commit()
    db.refresh(db_box)
    
    return db_box


@router.delete("/bounding-boxes/{box_id}")
def delete_bounding_box(box_id: str, db: Session = Depends(get_db)):
    box = db.query(BoundingBox).filter(BoundingBox.id == box_id).first()
    if not box:
        raise HTTPException(status_code=404, detail="Bounding box not found")
    
    db.delete(box)
    db.commit()
    return {"message": "Bounding box deleted successfully"}
