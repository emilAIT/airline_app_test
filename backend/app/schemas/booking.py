"""Booking schemas."""
from pydantic import BaseModel, Field
from datetime import date, datetime
from decimal import Decimal
from typing import List, Optional


class SeatInfo(BaseModel):
    """Seat information."""
    row_number: int
    seat_letter: str
    category: str  # 'standard' or 'extra_legroom'
    
    class Config:
        from_attributes = True


class PassengerInput(BaseModel):
    """Passenger for booking."""
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    seat_number: str = Field(max_length=10)
    # Required for additional passengers
    passport_number: str = Field(min_length=1, max_length=20)
    nationality: str = Field(min_length=1, max_length=100)
    date_of_birth: date  # YYYY-MM-DD


class BookingCreate(BaseModel):
    """Create booking request."""
    flight_id: int
    passengers: List[PassengerInput] = Field(min_length=1)


class TicketInfo(BaseModel):
    """Ticket information in booking response."""
    ticket_number: str
    passenger_first_name: str
    passenger_last_name: str
    seat_number: str
    seat: Optional[SeatInfo] = None  # Nested seat object
    price: Decimal
    
    class Config:
        from_attributes = True


class PassengerInfo(BaseModel):
    """Passenger info returned in booking responses."""

    first_name: str
    last_name: str
    seat_number: str
    ticket_number: str
    passport_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[date] = None


class BookingResponse(BaseModel):
    """Booking response."""
    id: int
    # Backward/forward compatibility for clients that expect `booking_id`.
    booking_id: int
    pnr: str
    flight_id: int
    total_amount: Decimal
    status: str
    created_at: datetime
    seats_held_until: datetime | None = None  # For CREATED status
    tickets: List[TicketInfo]
    passengers: List[PassengerInfo]
    
    class Config:
        from_attributes = True


class PaymentRequest(BaseModel):
    """Payment request."""
    booking_pnr: str = Field(max_length=6)
    idempotency_key: str = Field(max_length=100)  # UUID v4 from client
    payment_method: str = "MOCK_CARD"


class PaymentResponse(BaseModel):
    """Payment response."""
    payment_id: int
    booking_pnr: str
    amount: Decimal
    status: str  # PAID or FAILED
    booking_status: str  # CONFIRMED if payment success
