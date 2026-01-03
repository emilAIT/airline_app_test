"""
Passenger Profiles API routes.

Endpoints:
- POST /profile: Create passenger profile
- GET /profiles: List user's profiles
- GET /profile/{id}: Get specific profile
- PUT /profile/{id}: Update profile
- DELETE /profile/{id}: Delete profile

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_passenger
from app.models.user import User, UserRole
from app.models.passenger import PassengerProfile
from app.schemas.passenger import PassengerProfileCreate, PassengerProfileUpdate, PassengerProfileResponse

router = APIRouter(prefix="/passengers", tags=["Passengers"])


@router.post("/profile", response_model=PassengerProfileResponse, status_code=status.HTTP_201_CREATED)
def create_profile(
    profile_data: PassengerProfileCreate,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Create passenger profile"""
    # Check if Staff/Admin already has a profile
    if current_user.role in [UserRole.STAFF, UserRole.ADMIN]:
        existing = db.query(PassengerProfile).filter(
            PassengerProfile.user_id == current_user.id
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Staff and Admin accounts can only have one passenger profile"
            )
            
    profile = PassengerProfile(
        user_id=current_user.id,
        **profile_data.dict()
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.get("/profiles", response_model=List[PassengerProfileResponse])
def list_profiles(
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """List all passenger profiles for the current user"""
    profiles = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == current_user.id
    ).all()
    return profiles


@router.get("/profile/{profile_id}", response_model=PassengerProfileResponse)
def get_profile(
    profile_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get a specific passenger profile"""
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.id == profile_id,
        PassengerProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    return profile


@router.put("/profile/{profile_id}", response_model=PassengerProfileResponse)
def update_profile(
    profile_id: int,
    profile_data: PassengerProfileUpdate,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Update a specific passenger profile"""
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.id == profile_id,
        PassengerProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    update_data = profile_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)
    
    db.commit()
    db.refresh(profile)
    return profile


@router.delete("/profile/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_profile(
    profile_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Delete a passenger profile"""
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.id == profile_id,
        PassengerProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Refresh booking statuses to ensure we aren't blocked by stale EXPIRED holds
    from app.services.booking import cancel_expired_bookings
    cancel_expired_bookings(db)

    # Check for associated active tickets
    from app.models.booking import Ticket, Booking, BookingStatus
    active_tickets_count = db.query(Ticket).join(Booking).filter(
        Ticket.passenger_profile_id == profile_id,
        Booking.status.in_([BookingStatus.HOLD, BookingStatus.CONFIRMED])
    ).count()
    
    if active_tickets_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete profile because it is associated with {active_tickets_count} active/upcoming ticket(s). Cancel the bookings first."
        )
    
    db.delete(profile)
    db.commit()
    return None
