from typing import Generator, Optional
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from app.core import database, security, config
from app.models import user as user_model
from app.schemas import user as user_schema

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{config.settings.API_V1_STR}/auth/login/access-token"
)

def get_db() -> Generator:
    try:
        db = database.SessionLocal()
        yield db
    finally:
        db.close()

def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(reusable_oauth2)
) -> user_model.User:
    try:
        payload = jwt.decode(
            token, config.settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = user_schema.TokenData(email=payload.get("sub"))
    except (JWTError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    user = db.query(user_model.User).filter(user_model.User.email == token_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

def get_current_active_user(
    current_user: user_model.User = Depends(get_current_user),
) -> user_model.User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

def get_current_active_user_optional(
    request: Request,
    db: Session = Depends(get_db),
) -> Optional[user_model.User]:
    """Optional authentication - returns None if not authenticated"""
    try:
        # Try to get token from Authorization header manually
        authorization: str = request.headers.get("Authorization", "")
        if not authorization or not authorization.startswith("Bearer "):
            return None
        token = authorization.replace("Bearer ", "").strip()
        if not token:
            return None
    except Exception:
        return None
    
    try:
        payload = jwt.decode(
            token, config.settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = user_schema.TokenData(email=payload.get("sub"))
        if not token_data.email:
            return None
    except (JWTError, ValueError):
        return None
    
    user = db.query(user_model.User).filter(user_model.User.email == token_data.email).first()
    if user is None or not user.is_active:
        return None
    return user

def get_current_active_superuser(
    current_user: user_model.User = Depends(get_current_user),
) -> user_model.User:
    if current_user.role != user_model.UserRole.STAFF:
        raise HTTPException(
            status_code=400, detail="The user doesn't have enough privileges"
        )
    return current_user
