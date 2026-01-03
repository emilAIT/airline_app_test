from pydantic import BaseModel
from typing import Optional


class PassengerProfileBase(BaseModel):
    first_name: str
    last_name: str
    passport_number: str
    nationality: str
    date_of_birth: str  # ISO Format YYYY-MM-DD
    phone_number: Optional[str] = None


class PassengerProfileCreate(PassengerProfileBase):
    pass


class PassengerProfileUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    passport_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[str] = None
    phone_number: Optional[str] = None


class PassengerProfileResponse(PassengerProfileBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

