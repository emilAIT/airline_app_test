from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.models.booking import BookingStatus


class PassengerData(BaseModel):
    """Data for a passenger in a booking"""
    passenger_profile_id: int
    seat_number: str
    seat_category: Optional[str] = "STANDARD"


class BookingCreate(BaseModel):
    flight_id: int
    passengers: List[PassengerData]  # Changed from passenger_profiles


class BookingResponse(BaseModel):
    id: int
    pnr: str
    user_id: int
    flight_id: int
    status: BookingStatus
    held_until: Optional[datetime]  # Changed from seat_hold_expires_at
    created_at: datetime

    class Config:
        from_attributes = True
