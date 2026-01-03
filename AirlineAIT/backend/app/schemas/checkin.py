from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any


class CheckInResponse(BaseModel):
    id: int
    ticket_id: int
    checked_in_at: datetime
    qr_code: str
    # ticket: Optional[Dict[str, Any]] = None
    # flight: Optional[Dict[str, Any]] = None
    
    class Config:
        from_attributes = True


class BoardingPassResponse(BaseModel):
    passenger_name: str
    passenger_nationality: Optional[str] = None
    passenger_passport_number: Optional[str] = None
    flight_number: str
    seat: Optional[str]
    gate: Optional[str]
    terminal: Optional[str] = None
    boarding_time: datetime
    departure_time: datetime
    arrival_time: datetime
    departure_airport_code: str
    departure_airport_name: str
    arrival_airport_code: str
    arrival_airport_name: str
    qr_code: str  # Base64 encoded QR code image

