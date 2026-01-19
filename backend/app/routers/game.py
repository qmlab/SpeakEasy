import random
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Object, ObjectImage, BoundingBox, Player, AttemptHistory
from app.schemas.attempt import SayWordRequest, SayWordResponse, FindObjectRequest, FindObjectResponse
from app.schemas.object import ObjectResponse, ObjectImageResponse
from app.services.scoring import ScoringService

router = APIRouter(prefix="/game", tags=["game"])


@router.post("/say-word", response_model=SayWordResponse)
def say_word(request: SayWordRequest, db: Session = Depends(get_db)):
    player = db.query(Player).filter(Player.id == request.player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    obj = db.query(Object).filter(Object.id == request.object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    
    score, is_correct, feedback = ScoringService.score_pronunciation(
        obj.name, request.spoken_text
    )
    
    attempt = AttemptHistory(
        player_id=request.player_id,
        object_id=request.object_id,
        feature_type=1,
        score=score,
        spoken_text=request.spoken_text,
        is_correct=is_correct
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    
    return SayWordResponse(
        score=score,
        is_correct=is_correct,
        target_word=obj.name,
        spoken_text=request.spoken_text,
        feedback=feedback,
        attempt_id=attempt.id
    )


@router.post("/find-object", response_model=FindObjectResponse)
def find_object(request: FindObjectRequest, db: Session = Depends(get_db)):
    player = db.query(Player).filter(Player.id == request.player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    image = db.query(ObjectImage).filter(ObjectImage.id == request.object_image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    obj = db.query(Object).filter(Object.id == image.object_id).first()
    
    bounding_boxes = db.query(BoundingBox).filter(
        BoundingBox.object_image_id == request.object_image_id
    ).all()
    
    if not bounding_boxes:
        raise HTTPException(
            status_code=400,
            detail="This image has no bounding boxes defined"
        )
    
    is_correct = False
    best_score = 0
    correct_box = None
    
    for box in bounding_boxes:
        hit, score = ScoringService.check_tap_location(
            request.tap_x, request.tap_y,
            box.x, box.y, box.width, box.height
        )
        if hit and score > best_score:
            is_correct = True
            best_score = score
            correct_box = box
    
    if not is_correct:
        correct_box = bounding_boxes[0]
    
    attempt = AttemptHistory(
        player_id=request.player_id,
        object_id=obj.id,
        feature_type=2,
        score=best_score,
        tap_x=request.tap_x,
        tap_y=request.tap_y,
        is_correct=is_correct
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    
    if is_correct:
        feedback = f"Great job! You found the {obj.name}!"
    else:
        feedback = f"Not quite! Try to find the {obj.name}."
    
    correct_location = None
    if not is_correct and correct_box:
        correct_location = {
            "x": correct_box.x,
            "y": correct_box.y,
            "width": correct_box.width,
            "height": correct_box.height
        }
    
    return FindObjectResponse(
        is_correct=is_correct,
        score=best_score,
        feedback=feedback,
        correct_location=correct_location,
        attempt_id=attempt.id
    )


@router.get("/random-object", response_model=ObjectResponse)
def get_random_object(category: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(Object)
    
    if category:
        query = query.filter(Object.category == category)
    
    objects = query.all()
    
    if not objects:
        raise HTTPException(status_code=404, detail="No objects found")
    
    return random.choice(objects)


@router.get("/random-image-with-boxes", response_model=ObjectImageResponse)
def get_random_image_with_boxes(
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(ObjectImage).join(Object).join(BoundingBox)
    
    if category:
        query = query.filter(Object.category == category)
    
    images = query.distinct().all()
    
    if not images:
        raise HTTPException(
            status_code=404,
            detail="No images with bounding boxes found"
        )
    
    return random.choice(images)


@router.get("/challenge/{player_id}")
def get_challenge(
    player_id: str,
    feature_type: int = 1,
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    player = db.query(Player).filter(Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    if feature_type == 1:
        query = db.query(Object)
        if category:
            query = query.filter(Object.category == category)
        
        objects = query.all()
        if not objects:
            raise HTTPException(status_code=404, detail="No objects found")
        
        obj = random.choice(objects)
        
        image_url = None
        if obj.images:
            image_url = obj.images[0].image_url
        
        return {
            "feature_type": 1,
            "object_id": obj.id,
            "object_name": obj.name,
            "category": obj.category,
            "image_url": image_url,
            "instruction": f"Say the word: {obj.name}"
        }
    
    elif feature_type == 2:
        query = db.query(ObjectImage).join(Object).join(BoundingBox)
        if category:
            query = query.filter(Object.category == category)
        
        images = query.distinct().all()
        if not images:
            raise HTTPException(
                status_code=404,
                detail="No images with bounding boxes found"
            )
        
        image = random.choice(images)
        obj = image.object
        
        return {
            "feature_type": 2,
            "object_image_id": image.id,
            "object_id": obj.id,
            "object_name": obj.name,
            "category": obj.category,
            "image_url": image.image_url,
            "instruction": f"Find the {obj.name} in the picture!"
        }
    
    else:
        raise HTTPException(status_code=400, detail="Invalid feature_type. Use 1 or 2.")
