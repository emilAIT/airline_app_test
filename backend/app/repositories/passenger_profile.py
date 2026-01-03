"""
PassengerProfile repository - database operations for passenger profiles.
"""
from typing import Optional
from sqlalchemy.orm import Session
from app.models.passenger_profile import PassengerProfile


class PassengerProfileRepository:
    """Data access layer for PassengerProfile model."""
    
    def create(self, db: Session, user_id: int, **profile_data) -> PassengerProfile:
        """Create new passenger profile."""
        profile = PassengerProfile(user_id=user_id, **profile_data)
        db.add(profile)
        db.flush()
        db.refresh(profile)
        return profile
    
    def get_by_user_id(self, db: Session, user_id: int) -> Optional[PassengerProfile]:
        """Get profile by user ID."""
        return db.query(PassengerProfile).filter(PassengerProfile.user_id == user_id).first()
    
    def update(self, db: Session, profile: PassengerProfile, **update_data) -> PassengerProfile:
        """Update existing profile."""
        for key, value in update_data.items():
            if value is not None:  # Only update non-None values
                setattr(profile, key, value)
        db.flush()
        db.refresh(profile)
        return profile


# Singleton
passenger_profile_repository = PassengerProfileRepository()
