from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import get_password_hash, create_access_token
from app.models.user import User, UserRole
from app.models.passenger_profile import PassengerProfile
from app.schemas.user import UserCreate, UserLogin
from app.schemas.passenger_profile import PassengerProfileCreate

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user (passenger or staff).
    Per instructions.txt line 141.
    """
    # Validate and normalize role
    role_str = user_data.role.upper()
    try:
        role = UserRole[role_str]
    except KeyError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role must be 'PASSENGER' or 'STAFF' (case-insensitive)"
        )
    
    # Check if username or email already exists
    existing = db.query(User).filter(
        (User.username == user_data.username) | (User.email == user_data.email)
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create user
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        role=role
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "role": user.role.value
    }


@router.post("/login")
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """
    Login and get JWT token.
    Per instructions.txt lines 139-144.
    """
    from app.core.security import verify_password
    
    # Find user by username
    user = db.query(User).filter(User.username == login_data.username).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Create access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "role": user.role.value
        }
    }


@router.get("/me")
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role.value
    }


@router.post("/profile", status_code=status.HTTP_201_CREATED)
def create_passenger_profile(
    profile_data: PassengerProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create or update passenger profile.
    Per instructions.txt line 144: profile must be completed before booking.
    """
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only passengers can create profiles"
        )
    
    # Check if profile already exists
    existing_profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == current_user.id
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
        user_id=current_user.id,
        **profile_data.dict()
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.get("/profile")
def get_passenger_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get passenger profile"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only passengers have profiles"
        )
    
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please create a profile first."
        )
    
    return profile
