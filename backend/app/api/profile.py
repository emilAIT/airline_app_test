"""
Passenger Profile API routes.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.passenger_profile import PassengerProfileCreate, PassengerProfileUpdate, PassengerProfileResponse
from app.services.passenger_profile_service import passenger_profile_service

router = APIRouter()


@router.get("/", response_model=PassengerProfileResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's passenger profile.
    
    Requires authentication.
    """
    return passenger_profile_service.get_profile(db, current_user.id)


@router.put("/", response_model=PassengerProfileResponse)
def upsert_my_profile(
    data: PassengerProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create or update passenger profile for current user.
    
    This is an idempotent operation:
    - If profile exists: updates it
    - If profile missing: creates it
    
    Profile must be fully completed before booking flights.
    """
    from app.core.exceptions import DuplicateResource
    from app.schemas.passenger_profile import PassengerProfileUpdate
    
    try:
        # Try to create first
        return passenger_profile_service.create_profile(db, current_user.id, data)
    except DuplicateResource:
        # Profile already exists, update it instead
        update_data = PassengerProfileUpdate(**data.model_dump())
        return passenger_profile_service.update_profile(db, current_user.id, update_data)
