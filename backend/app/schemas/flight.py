"""
Flight schemas for request/response validation.
"""
from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from enum import Enum
from decimal import Decimal
from typing import Optional


class FlightStatus(str, Enum):
    """Flight status options."""
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class SeatClass(str, Enum):
    """Seat class options."""
    ECONOMY = "ECONOMY"
    BUSINESS = "BUSINESS"
    FIRST = "FIRST"


# Request schemas

class FlightCreate(BaseModel):
    """Create flight request (staff only)."""
    flight_number: str = Field(max_length=10)
    airplane_id: int
    origin_airport_id: int
    destination_airport_id: int
    departure_time: datetime
    arrival_time: datetime
    base_price: Decimal = Field(gt=0)
    
    @field_validator('flight_number')
    def flight_number_uppercase(cls, v):
        return v.upper()


class FlightStatusUpdate(BaseModel):
    """Update flight status (staff only)."""
    status: FlightStatus


# Response schemas

class AirportInfo(BaseModel):
    """Airport info in flight response."""
    code: str
    city: str
    
    class Config:
        from_attributes = True


class FlightResponse(BaseModel):
    """Flight response."""
    id: int
    flight_number: str
    origin_airport: AirportInfo = Field(serialization_alias="origin")
    destination_airport: AirportInfo = Field(serialization_alias="destination")
    departure_time: datetime
    arrival_time: datetime
    base_price: Decimal
    status: FlightStatus
    available_seats: int = 0  # Computed field
    
    class Config:
        from_attributes = True


class SeatInfo(BaseModel):
    """Seat information with availability."""
    seat_number: str
    seat_class: SeatClass
    available: bool
    price: Decimal


class SeatMapResponse(BaseModel):
    """Seat map for a flight."""
    flight_id: int
    airplane: str  # Airplane model
    seats: list[SeatInfo]
