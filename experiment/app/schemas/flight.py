from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
from app.models.flight import FlightStatus, AnnouncementType
from app.schemas.aviation import Airport, Airplane

# Announcement
class AnnouncementBase(BaseModel):
    title: str
    message: str
    type: AnnouncementType

class AnnouncementCreate(AnnouncementBase):
    flight_id: int

class Announcement(AnnouncementBase):
    id: int
    created_at: datetime
    flight_id: int
    user_id: Optional[int] = None  # NULL = public, not NULL = personal

    class Config:
        from_attributes = True

# Flight
class FlightBase(BaseModel):
    flight_number: str
    departure_airport_code: str
    arrival_airport_code: str
    airplane_id: int
    departure_time: datetime
    arrival_time: datetime
    base_price: float
    gate: Optional[str] = None
    terminal: Optional[str] = None

class FlightCreate(FlightBase):
    pass

class FlightUpdate(BaseModel):
    status: Optional[FlightStatus] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None
    departure_time: Optional[datetime] = None
    arrival_time: Optional[datetime] = None

class Flight(FlightBase):
    id: int
    status: FlightStatus
    
    # Nested objects for response
    # departure_airport: Airport
    # arrival_airport: Airport
    # airplane: Airplane

    class Config:
        from_attributes = True
