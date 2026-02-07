from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.player import Player
from app.schemas.player import AppleSignInRequest, AppleSignInResponse, PlayerResponse, GuestSignInRequest, GuestSignInResponse

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/apple", response_model=AppleSignInResponse)
def apple_sign_in(request: AppleSignInRequest, db: Session = Depends(get_db)):
    existing_player = db.query(Player).filter(
        Player.apple_user_id == request.apple_user_id
    ).first()
    
    if existing_player:
        if request.name and request.name != existing_player.name:
            existing_player.name = request.name
        if request.email and request.email != existing_player.email:
            existing_player.email = request.email
        db.commit()
        db.refresh(existing_player)
        
        return AppleSignInResponse(
            id=existing_player.id,
            name=existing_player.name,
            apple_user_id=existing_player.apple_user_id,
            email=existing_player.email,
            is_new_user=False,
            created_at=existing_player.created_at,
            updated_at=existing_player.updated_at
        )
    
    name = request.name or f"Player_{request.apple_user_id[:8]}"
    new_player = Player(
        name=name,
        apple_user_id=request.apple_user_id,
        email=request.email
    )
    db.add(new_player)
    db.commit()
    db.refresh(new_player)
    
    return AppleSignInResponse(
        id=new_player.id,
        name=new_player.name,
        apple_user_id=new_player.apple_user_id,
        email=new_player.email,
        is_new_user=True,
        created_at=new_player.created_at,
        updated_at=new_player.updated_at
    )


@router.get("/player/{apple_user_id}", response_model=PlayerResponse)
def get_player_by_apple_id(apple_user_id: str, db: Session = Depends(get_db)):
    player = db.query(Player).filter(
        Player.apple_user_id == apple_user_id
    ).first()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    return player


@router.post("/guest", response_model=GuestSignInResponse)
def guest_sign_in(request: GuestSignInRequest, db: Session = Depends(get_db)):
    existing_player = db.query(Player).filter(
        Player.device_id == request.device_id
    ).first()
    
    if existing_player:
        return GuestSignInResponse(
            id=existing_player.id,
            name=existing_player.name,
            device_id=existing_player.device_id,
            is_guest=existing_player.is_guest == "true",
            is_new_user=False,
            created_at=existing_player.created_at,
            updated_at=existing_player.updated_at
        )
    
    short_id = request.device_id[-6:].upper() if len(request.device_id) >= 6 else request.device_id.upper()
    name = f"Guest_{short_id}"
    new_player = Player(
        name=name,
        device_id=request.device_id,
        is_guest="true"
    )
    db.add(new_player)
    db.commit()
    db.refresh(new_player)
    
    return GuestSignInResponse(
        id=new_player.id,
        name=new_player.name,
        device_id=new_player.device_id,
        is_guest=True,
        is_new_user=True,
        created_at=new_player.created_at,
        updated_at=new_player.updated_at
    )


@router.get("/guest/{device_id}", response_model=PlayerResponse)
def get_player_by_device_id(device_id: str, db: Session = Depends(get_db)):
    player = db.query(Player).filter(
        Player.device_id == device_id
    ).first()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    return player
