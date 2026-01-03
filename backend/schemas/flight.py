from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.flight import FlightStatus


class FlightBase(BaseModel):
    flight_number: str
    origin_id: int
    destination_id: int
    airplane_id: int
    scheduled_departure: datetime
    scheduled_arrival: datetime
    price: float  # Added per instructions.txt
    gate: Optional[str] = None
    terminal: Optional[str] = None


class FlightCreate(FlightBase):
    pass


class FlightUpdate(BaseModel):
    """Schema for updating flight details"""
    flight_number: Optional[str] = None
    origin_id: Optional[int] = None
    destination_id: Optional[int] = None
    airplane_id: Optional[int] = None
    scheduled_departure: Optional[datetime] = None
    scheduled_arrival: Optional[datetime] = None
    price: Optional[float] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None
    status: Optional[str] = None


class FlightSearchRequest(BaseModel):
    """Schema for flight search request"""
    origin_id: int
    destination_id: int
    departure_date: str  # YYYY-MM-DD format


class FlightResponse(BaseModel):
    id: int
    flight_number: str
    origin_id: int
    destination_id: int
    airplane_id: int
    scheduled_departure: datetime
    scheduled_arrival: datetime
    price: float
    gate: Optional[str]
    terminal: Optional[str]
    status: FlightStatus
    created_at: datetime

    class Config:
        from_attributes = True
