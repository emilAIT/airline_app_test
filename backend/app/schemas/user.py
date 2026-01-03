"""
User schemas for request/response validation.
"""
from pydantic import BaseModel, EmailStr, Field, field_validator
from enum import Enum
from datetime import datetime
from typing import Optional


class UserRole(str, Enum):
    """User roles in the system."""
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"


# Request schemas

class UserRegister(BaseModel):
    """Registration request - создает PASSENGER пользователя."""
    email: EmailStr
    # Keep a sane upper bound to avoid abuse; actual hashing supports long
    # passwords safely (see security.py).
    password: str = Field(min_length=8, max_length=256)

    @field_validator('password')
    @classmethod
    def password_max_72_bytes(cls, v: str) -> str:
        # Hard cap in bytes to prevent pathological payloads (and to keep UX
        # reasonable with multibyte characters).
        if len(v.encode('utf-8')) > 512:
            raise ValueError('Пароль слишком длинный')
        return v


class UserLogin(BaseModel):
    """Login request."""
    email: EmailStr
    password: str = Field(max_length=256)

    @field_validator('password')
    @classmethod
    def password_max_72_bytes(cls, v: str) -> str:
        if len(v.encode('utf-8')) > 512:
            raise ValueError('Пароль слишком длинный')
        return v


# Response schemas

class UserResponse(BaseModel):
    """User response (without password)."""
    id: int
    email: str
    role: UserRole
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True  # Enable ORM mode for SQLAlchemy models


class TokenResponse(BaseModel):
    """JWT token response."""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
