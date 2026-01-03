from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional, Dict, Any
from app.models.booking import BookingStatus
from app.schemas.flight import FlightResponse


class PassengerInfo(BaseModel):
    passenger_profile_id: int
    seat_number: Optional[str] = None


class BookingCreate(BaseModel):
    flight_id: int
    passengers: List[PassengerInfo]


class TicketResponse(BaseModel):
    id: int
    ticket_number: str
    passenger_profile_id: int
    seat_number: Optional[str]
    price: Optional[float] = None
    passenger_name: Optional[str] = None
    is_checked_in: bool = False
    
    class Config:
        from_attributes = True


class BookingResponse(BaseModel):
    id: int
    pnr: str
    user_id: int
    flight_id: int
    status: str
    created_at: datetime
    server_time: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    tickets: List[TicketResponse]
    flight: Optional[FlightResponse] = None
    
    class Config:
        from_attributes = True


class BookingDetailResponse(BookingResponse):
    payments: List[Dict[str, Any]]
    check_ins: List[Dict[str, Any]]

