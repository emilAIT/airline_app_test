from pydantic import BaseModel, Field
from datetime import date
from typing import Optional


class PassengerProfileBase(BaseModel):
    full_name: Optional[str] = Field(None, example="John Smith")
    phone: Optional[str] = Field(None, example="+996700123456")
    passport_number: Optional[str] = Field(None, example="AN1234567")
    nationality: Optional[str] = Field(None, example="Kyrgyzstan")
    date_of_birth: Optional[date] = Field(
        None,
        example="1995-08-21",
    )


class PassengerProfileUpdate(BaseModel):
    full_name: str = Field(..., example="John Smith")
    phone: str = Field(..., example="+996700123456")
    passport_number: str = Field(..., example="AN1234567")
    nationality: str = Field(..., example="Kyrgyzstan")
    date_of_birth: date = Field(
        ..., example="1995-08-21"
    )
    
class PassengerProfileResponse(BaseModel):
    full_name: str
    phone: str
    passport_number: str
    nationality: str
    date_of_birth: date

    class Config:
        from_attributes = True
