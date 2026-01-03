from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from datetime import timedelta
from typing import Optional
from app.models.user import User, UserRole
from app.schemas.auth import UserRegister
from app.utils.security import verify_password, get_password_hash, create_access_token
from app.core.config import settings


def create_user(db: Session, user_data: UserRegister, role: UserRole = UserRole.PASSENGER, assigned_airplane_id: Optional[int] = None) -> User:
    # Normalize email to lowercase for case-insensitive comparison
    email_lower = user_data.email.lower().strip()
    
    if not email_lower:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email cannot be empty"
        )
    
    # Check if user already exists (case-insensitive)
    # Try multiple approaches for compatibility
    existing_user = None
    try:
        # First try: case-insensitive query using func.lower
        existing_user = db.query(User).filter(
            func.lower(User.email) == email_lower
        ).first()
        
        # Fallback: if func.lower doesn't work, check all users manually
        if existing_user is None:
            all_users = db.query(User).all()
            for u in all_users:
                if u.email and u.email.lower().strip() == email_lower:
                    existing_user = u
                    break
    except Exception as e:
        # If query fails, try manual check
        all_users = db.query(User).all()
        for u in all_users:
            if u.email and u.email.lower().strip() == email_lower:
                existing_user = u
                break
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user (store email in lowercase)
    try:
        # Hash password with improved error handling
        try:
            hashed_password = get_password_hash(user_data.password)
        except Exception as hash_error:
            # If password hashing fails, provide a clear error
            error_msg = str(hash_error)
            if "72 bytes" in error_msg:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Password is too long. Please use a shorter password."
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Password hashing failed: {error_msg}"
            )
        
        user = User(
            email=email_lower,
            hashed_password=hashed_password,
            role=role,
            is_approved=role != UserRole.STAFF,  # False for STAFF, True for others
            assigned_airplane_id=assigned_airplane_id if role == UserRole.STAFF else None
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        db.rollback()
        # Check if it's a unique constraint violation
        error_str = str(e).lower()
        if "unique" in error_str or "constraint" in error_str:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        # Re-raise other errors with details
        import traceback
        error_details = traceback.format_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create user: {str(e)}"
        )


def authenticate_user(db: Session, email: str, password: str) -> User:
    # Normalize email to lowercase for case-insensitive comparison
    email_lower = email.lower().strip()
    # Try multiple approaches for compatibility
    user = None
    try:
        user = db.query(User).filter(
            func.lower(User.email) == email_lower
        ).first()
        
        if user is None:
            # Fallback for some SQLite versions
            all_users = db.query(User).all()
            for u in all_users:
                if u.email and u.email.lower().strip() == email_lower:
                    user = u
                    break
    except Exception:
        # Final fallback
        all_users = db.query(User).all()
        for u in all_users:
            if u.email and u.email.lower().strip() == email_lower:
                user = u
                break
                
    if not user:
        print(f"DEBUG AUTH: User not found for email: '{email_lower}'")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    print(f"DEBUG AUTH: Found user: {user.email}, Role: {user.role}, Active: {user.is_active}")
    print(f"DEBUG AUTH: Received password: '{password}'")
    
    if not verify_password(password, user.hashed_password):
        print(f"DEBUG AUTH: Password verification failed for user: {user.email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Check if STAFF is approved
    if user.role == UserRole.STAFF and not user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Staff account pending approval. Please wait for admin approval."
        )
    
    return user


def create_access_token_for_user(user: User) -> str:
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": user.email,
        "role": user.role.value,
        "user_id": user.id
    }
    if user.assigned_airplane_id:
        token_data["assigned_airplane_id"] = user.assigned_airplane_id
    access_token = create_access_token(
        data=token_data,
        expires_delta=access_token_expires
    )
    return access_token

