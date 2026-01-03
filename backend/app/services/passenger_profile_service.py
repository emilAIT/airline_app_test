"""
PassengerProfile service - business logic for passenger profiles.
"""
from sqlalchemy.orm import Session
from app.core.exceptions import NotFound, DuplicateResource
from app.repositories.passenger_profile import passenger_profile_repository
from app.schemas.passenger_profile import PassengerProfileCreate, PassengerProfileUpdate, PassengerProfileResponse
from sqlalchemy.exc import IntegrityError


class PassengerProfileService:
    """
    Business logic for passenger profiles.
    
    Business Rule:
        User must complete profile before creating bookings.
    """
    
    def create_profile(self, db: Session, user_id: int, data: PassengerProfileCreate) -> PassengerProfileResponse:
        """
        Create passenger profile for user.
        
        Raises:
            DuplicateResource: If profile already exists for user
        """
        # Check if profile already exists
        existing = passenger_profile_repository.get_by_user_id(db, user_id)
        if existing:
            raise DuplicateResource("Profile")
        
        try:
            profile = passenger_profile_repository.create(
                db=db,
                user_id=user_id,
                **data.model_dump()
            )
            db.commit()
            return PassengerProfileResponse.model_validate(profile)
        except IntegrityError:
            db.rollback()
            raise DuplicateResource("Profile")
    
    def get_profile(self, db: Session, user_id: int) -> PassengerProfileResponse:
        """
        Get passenger profile by user ID.
        
        Raises:
            NotFound: If profile doesn't exist
        """
        profile = passenger_profile_repository.get_by_user_id(db, user_id)
        if not profile:
            raise NotFound("Profile")
        return PassengerProfileResponse.model_validate(profile)
    
    def update_profile(self, db: Session, user_id: int, data: PassengerProfileUpdate) -> PassengerProfileResponse:
        """
        Update passenger profile.
        
        Raises:
            NotFound: If profile doesn't exist
        """
        profile = passenger_profile_repository.get_by_user_id(db, user_id)
        if not profile:
            raise NotFound("Profile")
        
        # Only update fields that are provided
        update_data = {k: v for k, v in data.model_dump().items() if v is not None}
        
        updated_profile = passenger_profile_repository.update(db, profile, **update_data)
        db.commit()
        
        return PassengerProfileResponse.model_validate(updated_profile)

    def is_profile_complete(self, profile) -> bool:
        """
        Check if profile is complete.
        
        Rule: All fields must be non-null and valid.
        Required: first_name, last_name, phone, date_of_birth, passport_number, nationality.
        """
        required_fields = [
            profile.first_name,
            profile.last_name,
            profile.phone,
            profile.date_of_birth,
            profile.passport_number,
            profile.nationality
        ]
        # Check if all fields are truthy (not None and not empty string)
        return all(f is not None and f != "" for f in required_fields)


# Singleton
passenger_profile_service = PassengerProfileService()
