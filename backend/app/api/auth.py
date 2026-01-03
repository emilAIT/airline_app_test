"""
Authentication API routes - registration and login.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.schemas.user import UserRegister, UserLogin, TokenResponse
from app.services.auth_service import auth_service

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(data: UserRegister, db: Session = Depends(get_db)):
    """
    Register new passenger user.
    
    - Creates user with PASSENGER role
    - Returns JWT token for immediate login
    - Email must be unique
    """
    return auth_service.register_passenger(db, data)


@router.post("/login", response_model=TokenResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):
    """
    Login with email and password.
    
    - Returns JWT token on success
    - Token contains user_id and role in payload
    """
    return auth_service.login(db, data)
