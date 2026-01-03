"""
PassengerProfile schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class PassengerProfileCreate(BaseModel):
    """Create passenger profile request."""
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[date] = None
    passport_number: Optional[str] = Field(None, max_length=50)
    nationality: Optional[str] = Field(None, max_length=100)


class PassengerProfileUpdate(BaseModel):
    """Update passenger profile request."""
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[date] = None
    passport_number: Optional[str] = Field(None, max_length=50)
    nationality: Optional[str] = Field(None, max_length=100)


class PassengerProfileResponse(BaseModel):
    """Passenger profile response."""
    id: int
    user_id: int
    first_name: str
    last_name: str
    phone: Optional[str]
    date_of_birth: Optional[date]
    passport_number: Optional[str]
    nationality: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True
