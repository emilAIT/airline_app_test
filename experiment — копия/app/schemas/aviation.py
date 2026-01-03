from typing import List, Optional
from pydantic import BaseModel

# Seat
class SeatBase(BaseModel):
    seat_number: str
    category: str

class SeatCreate(SeatBase):
    pass

class Seat(SeatBase):
    id: int
    airplane_id: int

    class Config:
        from_attributes = True

# Airplane
class AirplaneBase(BaseModel):
    name: str # Registration
    model: str

class AirplaneCreate(AirplaneBase):
    rows: int
    seats_per_row: int
    business_rows: int = 0

class AirplaneUpdate(BaseModel):
    name: Optional[str] = None
    model: Optional[str] = None

class Airplane(AirplaneBase):
    id: int
    seats: List[Seat] = []

    class Config:
        from_attributes = True

# Airport
class AirportBase(BaseModel):
    code: str
    name: str
    city: str
    country: str

class AirportCreate(AirportBase):
    pass

class AirportUpdate(BaseModel):
    name: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None

class Airport(AirportBase):
    class Config:
        from_attributes = True
