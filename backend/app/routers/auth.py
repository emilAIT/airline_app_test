from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import schemas
from ..database import get_db
from ..services import auth_service
from ..auth import get_current_passenger

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: schemas.UserRegister, db: Session = Depends(get_db)):
    """Register a new passenger account"""
    return auth_service.register_passenger(db, user_data)


@router.post("/login", response_model=schemas.Token)
def login(user_data: schemas.UserLogin, db: Session = Depends(get_db)):
    """Login and receive JWT token"""
    return auth_service.login_user(db, user_data)


@router.get("/profile", response_model=schemas.PassengerProfileResponse)
def get_profile(
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get current user's passenger profile"""
    return auth_service.get_passenger_profile(db, current_user.id)


@router.put("/profile", response_model=schemas.PassengerProfileResponse)
def update_profile(
    profile_data: schemas.PassengerProfileUpdate,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Update passenger profile (required before booking)"""
    return auth_service.update_passenger_profile(db, current_user.id, profile_data)

