from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
from app.models.booking import BookingStatus, PaymentStatus, PaymentMethod
from app.schemas.flight import Flight

class TicketBase(BaseModel):
    passenger_name: str
    passport_number: str  # Required passport number
    seat_number: Optional[str] = None  # Optional for auto-assignment

class TicketCreate(TicketBase):
    pass

class Ticket(TicketBase):
    id: int
    booking_id: int
    ticket_number: str
    passport_number: Optional[str] = None  # Optional in response for backward compatibility

    class Config:
        from_attributes = True

class BookingBase(BaseModel):
    flight_id: int

class BookingCreate(BookingBase):
    passengers: List[TicketCreate] # Need to handle logic of seat hold

class Booking(BookingBase):
    id: int
    pnr: str
    status: BookingStatus
    total_price: float
    created_at: datetime
    tickets: List[Ticket] = []
    flight: Flight

    class Config:
        from_attributes = True
