from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.passenger_profile import PassengerProfile
from app.schemas.passenger_profile import PassengerProfileCreate, PassengerProfileUpdate


def create_or_update_profile(
    db: Session, 
    user_id: int, 
    profile_data: PassengerProfileCreate
) -> PassengerProfile:
    existing_profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == user_id
    ).first()
    
    if existing_profile:
        # Update existing profile
        for key, value in profile_data.dict(exclude_unset=True).items():
            setattr(existing_profile, key, value)
        db.commit()
        db.refresh(existing_profile)
        return existing_profile
    
    # Create new profile
    profile = PassengerProfile(
        user_id=user_id,
        **profile_data.dict()
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def get_profile_by_user_id(db: Session, user_id: int) -> PassengerProfile:
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == user_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please create your profile first."
        )
    return profile
