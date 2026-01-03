from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any
from app.models.announcement import AnnouncementType


from app.schemas.flight import FlightResponse


class AnnouncementCreate(BaseModel):
    flight_id: Optional[int] = None
    type: AnnouncementType
    title: str
    message: str


class AnnouncementResponse(BaseModel):
    id: int
    flight_id: Optional[int] = None
    type: str
    title: str
    message: str
    created_at: datetime
    flight: Optional[FlightResponse] = None
    
    class Config:
        from_attributes = True

