from typing import Optional, List
from pydantic import BaseModel, EmailStr
from datetime import date, datetime
from enum import Enum

class UserRole(str, Enum):
    PASSENGER = "passenger"
    STAFF = "staff"

# Profile Schemas
class PassengerProfileBase(BaseModel):
    phone_number: Optional[str] = None
    passport_number: Optional[str] = None
    nationality: Optional[str] = None
    birth_date: Optional[date] = None

class PassengerProfileCreate(PassengerProfileBase):
    pass

class PassengerProfile(PassengerProfileBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# User Schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str
    role: UserRole = UserRole.PASSENGER

class User(UserBase):
    id: int
    is_active: bool
    role: UserRole
    profile: Optional[PassengerProfile] = None

    class Config:
        from_attributes = True

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# Notification Schemas
class UserNotificationType(str, Enum):
    BOOKING_CONFIRMED = "Booking Confirmed"
    TICKET_PURCHASED = "Ticket Purchased"
    FLIGHT_UPDATE = "Flight Update"

class UserNotificationBase(BaseModel):
    type: UserNotificationType
    message: str

class UserNotificationCreate(UserNotificationBase):
    user_id: int

class UserNotification(UserNotificationBase):
    id: int
    user_id: int
    created_at: datetime
    is_read: bool

    class Config:
        from_attributes = True
