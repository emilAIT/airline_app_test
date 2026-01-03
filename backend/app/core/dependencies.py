"""
FastAPI dependencies for database sessions and authentication.
"""
from typing import Generator
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError

from app.database import SessionLocal
from app.core.security import decode_access_token
from app.core.exceptions import InvalidToken, Forbidden
from app.models.user import User


# OAuth2 Bearer token scheme
http_bearer = HTTPBearer()


def get_db() -> Generator[Session, None, None]:
    """
    Dependency to get database session.
    
    Usage:
        @router.get("/something")
        def endpoint(db: Session = Depends(get_db)):
            ...
    
    Ensures session is closed after request.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(http_bearer),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency to get currently authenticated user from JWT token.
    
    Usage:
        @router.get("/protected")
        def endpoint(current_user: User = Depends(get_current_user)):
            ...
    
    Raises:
        InvalidToken: If token is invalid, expired, or user not found
    """
    token = credentials.credentials
    
    try:
        payload = decode_access_token(token)
        user_id: int = int(payload.get("sub"))
    except (JWTError, ValueError, TypeError):
        raise InvalidToken()
    
    # Fetch user from database
    user = db.query(User).filter(User.id == user_id).first()
    
    if user is None or not user.is_active:
        raise InvalidToken()
    
    return user


def require_role(required_role: str):
    """
    Dependency factory to require specific role.
    
    Usage:
        @router.post("/flights")
        def create_flight(
            current_user: User = Depends(require_role("STAFF")),
            ...
        ):
            ...
    
    Args:
        required_role: Role required to access endpoint (e.g., "STAFF")
        
    Returns:
        Dependency function that checks user role
        
    Raises:
        Forbidden: If user doesn't have required role
    """
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role != required_role:
            raise Forbidden(required_role=required_role)
        return current_user
    
    return role_checker
