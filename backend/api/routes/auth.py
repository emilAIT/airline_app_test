from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from schemas.auth import LoginRequest, RegisterRequest, Token
from models.user import User
from models.passenger_profile import PassengerProfile
from core.security import hash_password, verify_password, create_access_token
from core.dependencies import get_db

router = APIRouter()

# bcrypt limitation: max 72 bytes
def normalize_password(password: str) -> str:
    return password.encode("utf-8")[:72].decode("utf-8", errors="ignore")


@router.post("/register", response_model=Token)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    password = normalize_password(data.password)

    user = User(
        email=data.email,
        hashed_password=hash_password(password),
        role="PASSENGER",
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    if data.full_name:
        profile = PassengerProfile(
            user_id=user.id,
            full_name=data.full_name
        )
        db.add(profile)
        db.commit()

    token = create_access_token(subject=user.id)
    return {"access_token": token}


@router.post("/login", response_model=Token)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    password = normalize_password(data.password)

    if not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(subject=user.id)
    return {"access_token": token}