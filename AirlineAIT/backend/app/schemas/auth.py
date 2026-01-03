from pydantic import BaseModel, EmailStr
from typing import Optional


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    role: Optional[str] = "PASSENGER"  # PASSENGER or STAFF
    assigned_airplane_id: Optional[int] = None  # Required for STAFF, ignored for PASSENGER


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    is_active: bool
    is_approved: bool = True
    assigned_airplane_id: Optional[int] = None

    class Config:
        from_attributes = True

