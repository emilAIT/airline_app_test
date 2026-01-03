from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import timedelta
from .. import models, schemas
from ..auth import verify_password, get_password_hash, create_access_token
from ..config import settings
from ..enums import UserRole


def register_passenger(db: Session, user_data: schemas.UserRegister) -> models.User:
    # Check if user exists
    db_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    hashed_password = get_password_hash(user_data.password)
    db_user = models.User(
        email=user_data.email,
        hashed_password=hashed_password,
        role=UserRole.PASSENGER
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create passenger profile
    profile = models.PassengerProfile(user_id=db_user.id, is_complete=False)
    db.add(profile)
    db.commit()
    
    return db_user


def login_user(db: Session, user_data: schemas.UserLogin) -> dict:
    user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "id": user.id,
        "email": user.email,
        "role": user.role
    }


def update_passenger_profile(db: Session, user_id: int, profile_data: schemas.PassengerProfileUpdate) -> models.PassengerProfile:
    profile = db.query(models.PassengerProfile).filter(models.PassengerProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    
    profile.full_name = profile_data.full_name
    profile.phone_number = profile_data.phone_number
    profile.passport_number = profile_data.passport_number
    profile.nationality = profile_data.nationality
    profile.date_of_birth = profile_data.date_of_birth
    profile.is_complete = True
    
    db.commit()
    db.refresh(profile)
    return profile


def get_passenger_profile(db: Session, user_id: int) -> models.PassengerProfile:
    profile = db.query(models.PassengerProfile).filter(models.PassengerProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return profile

