from datetime import datetime, timedelta
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session, select
from app.database import get_session
from app.models import User, UserRole, UserStatus, PassengerProfile
from app.core.security import (
    verify_password, 
    create_access_token, 
    get_password_hash, 
    ACCESS_TOKEN_EXPIRE_MINUTES
)
from app.core.deps import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])

class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    email: str
    password: str
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    passport_number: str | None = None
    nationality: str | None = None
    role: str = "passenger"

class UserOut(BaseModel):
    id: int
    email: str
    role: str
    status: str
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    created_at: datetime

@router.post("/login", response_model=Token)
async def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    session: Annotated[Session, Depends(get_session)]
):
    user = session.exec(select(User).where(User.email == form_data.username)).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if user.status == UserStatus.PENDING_APPROVAL:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ваш аккаунт ожидает подтверждения администратором. Пожалуйста, попробуйте позже."
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "role": user.role}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=Token)
def register(user_in: UserCreate, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.email == user_in.email)).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    new_role = UserRole.PASSENGER
    new_status = UserStatus.ACTIVE

    role_lower = user_in.role.lower()
    if role_lower in ["staff", "STAFF"]:
        new_role = UserRole.STAFF
        new_status = UserStatus.PENDING_APPROVAL
    elif role_lower in ["admin", "ADMIN"]:
        new_role = UserRole.ADMIN
        new_status = UserStatus.ACTIVE
    
    user = User(
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        first_name=user_in.first_name,
        last_name=user_in.last_name,
        phone=user_in.phone,
        role=new_role,
        status=new_status
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    
    # Создаем PassengerProfile если указаны passport_number или nationality
    if user_in.passport_number or user_in.nationality:
        passenger_profile = PassengerProfile(
            user_id=user.id,
            passport_number=user_in.passport_number,
            nationality=user_in.nationality
        )
        session.add(passenger_profile)
        session.commit()
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "role": user.role}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserOut)
async def read_users_me(current_user: Annotated[User, Depends(get_current_user)]):
    return current_user
