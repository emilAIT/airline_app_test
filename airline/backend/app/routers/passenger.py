from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_user
from app.models.all_models import User, PassengerProfile, UserRole
from app.schemas.schemas import (
    PassengerProfileCreate, PassengerProfileUpdate, PassengerProfileOut
)

router = APIRouter(prefix="/passenger", tags=["Passenger"])


@router.get("/profile", response_model=PassengerProfileOut)
def get_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user's passenger profile"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can access this endpoint")

    profile = db.query(PassengerProfile).filter(PassengerProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found. Please create your profile first.")
    return profile


@router.post("/profile", response_model=PassengerProfileOut, status_code=status.HTTP_201_CREATED)
@router.post("/profile/", response_model=PassengerProfileOut, status_code=status.HTTP_201_CREATED)
def create_profile(
    profile_data: PassengerProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create passenger profile"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can create profiles")

    existing_profile = db.query(PassengerProfile).filter(PassengerProfile.user_id == current_user.id).first()
    if existing_profile:
        raise HTTPException(status_code=400, detail="Profile already exists. Use PUT to update.")

    profile = PassengerProfile(
        user_id=current_user.id,
        **profile_data.model_dump()
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.put("/profile", response_model=PassengerProfileOut)
@router.put("/profile/", response_model=PassengerProfileOut)
def update_profile(
    profile_data: PassengerProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update passenger profile"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can update profiles")

    profile = db.query(PassengerProfile).filter(PassengerProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    update_data = profile_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    return profile


@router.get("/profile/complete")
def check_profile_complete(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Check if profile is complete (required before booking)"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can access this endpoint")

    profile = db.query(PassengerProfile).filter(PassengerProfile.user_id == current_user.id).first()
    if not profile:
        return {"complete": False, "message": "Profile does not exist"}

    required_fields = ["passport_number", "phone_number", "nationality", "date_of_birth"]
    missing = [field for field in required_fields if not getattr(profile, field, None)]

    return {
        "complete": len(missing) == 0,
        "missing_fields": missing
    }

