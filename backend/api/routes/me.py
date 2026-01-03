from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.dependencies import require_passenger
from db.session import get_db
from models.passenger_profile import PassengerProfile
from schemas.passenger_profile import PassengerProfileUpdate
from models.user import User
from core.dependencies import get_current_user

router = APIRouter(
    prefix="/me",
    tags=["Me"],
)


@router.get("")
def get_me(
    current_user: User = Depends(require_passenger),
):
    profile = current_user.profile

    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
        "profile": (
            {
                "full_name": profile.full_name,
                "phone": profile.phone,
                "passport_number": profile.passport_number,
                "nationality": profile.nationality,
                "date_of_birth": profile.date_of_birth,
            }
            if profile
            else None
        ),
    }


@router.put("/profile_update")
def update_profile(
    data: PassengerProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_passenger),
):
    if current_user.profile is None:
        current_user.profile = PassengerProfile(
            user_id=current_user.id
        )

    current_user.profile.full_name = data.full_name
    current_user.profile.phone = data.phone
    current_user.profile.passport_number = data.passport_number
    current_user.profile.nationality = data.nationality
    current_user.profile.date_of_birth = data.date_of_birth

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return {"status": "ok"}

def is_profile_complete(profile) -> bool:
    if not profile:
        return False

    required_fields = [
        profile.full_name,
        profile.phone,
        profile.passport_number,
        profile.nationality,
        profile.date_of_birth
    ]

    return all(required_fields)

@router.get("/complete")
def check_profile_complete(
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    return {
        "complete": is_profile_complete(profile)
    }
