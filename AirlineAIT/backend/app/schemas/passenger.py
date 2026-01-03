from pydantic import BaseModel
from datetime import date
from typing import Optional


class PassengerProfileCreate(BaseModel):
    full_name: str
    phone_number: str
    passport_number: str
    nationality: str
    date_of_birth: date


class PassengerProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    passport_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[date] = None


class PassengerProfileResponse(BaseModel):
    id: int
    user_id: int
    full_name: str
    phone_number: str
    passport_number: str
    nationality: str
    date_of_birth: date

    class Config:
        from_attributes = True

