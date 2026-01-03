from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AirplaneBase(BaseModel):
    model: str
    registration: str
    manufacturer: str
    total_seats: int
    economy_seats: int
    premium_economy_seats: int = 0
    business_seats: int = 0
    first_class_seats: int = 0
    rows_count: int
    seats_per_row: int

class AirplaneCreate(AirplaneBase):
    pass

class AirplaneRead(AirplaneBase):
    id: int
    owner_id: Optional[int] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
