from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.database import get_session
from app.models import User, PassengerProfile, StaffProfile
from app.core.deps import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/users", tags=["users"])

class ProfileUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    passport_number: str | None = None
    nationality: str | None = None

class ProfileOut(BaseModel):
    id: int
    email: str
    role: str
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    passport_number: str | None = None
    nationality: str | None = None

@router.get("/me/profile", response_model=ProfileOut)
async def get_my_profile(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Get current user's profile with extended information"""
    profile_data = {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone": current_user.phone,
        "passport_number": None,
        "nationality": None
    }
    
    # Get passenger profile if exists
    passenger_profile = session.exec(
        select(PassengerProfile).where(PassengerProfile.user_id == current_user.id)
    ).first()
    
    if passenger_profile:
        profile_data["passport_number"] = passenger_profile.passport_number
        profile_data["nationality"] = passenger_profile.nationality
    
    return profile_data

@router.put("/me/profile", response_model=ProfileOut)
async def update_my_profile(
    profile_update: ProfileUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Update current user's profile"""
    # Update User fields
    if profile_update.first_name is not None:
        current_user.first_name = profile_update.first_name
    if profile_update.last_name is not None:
        current_user.last_name = profile_update.last_name
    if profile_update.phone is not None:
        current_user.phone = profile_update.phone
    
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    
    # Update or create PassengerProfile if passport_number or nationality provided
    if profile_update.passport_number is not None or profile_update.nationality is not None:
        passenger_profile = session.exec(
            select(PassengerProfile).where(PassengerProfile.user_id == current_user.id)
        ).first()
        
        if passenger_profile:
            if profile_update.passport_number is not None:
                passenger_profile.passport_number = profile_update.passport_number
            if profile_update.nationality is not None:
                passenger_profile.nationality = profile_update.nationality
            session.add(passenger_profile)
        else:
            # Create new PassengerProfile
            passenger_profile = PassengerProfile(
                user_id=current_user.id,
                passport_number=profile_update.passport_number,
                nationality=profile_update.nationality
            )
            session.add(passenger_profile)
        
        session.commit()
        session.refresh(passenger_profile)
    
    # Return updated profile
    profile_data = {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone": current_user.phone,
        "passport_number": None,
        "nationality": None
    }
    
    passenger_profile = session.exec(
        select(PassengerProfile).where(PassengerProfile.user_id == current_user.id)
    ).first()
    
    if passenger_profile:
        profile_data["passport_number"] = passenger_profile.passport_number
        profile_data["nationality"] = passenger_profile.nationality
    
    return profile_data




