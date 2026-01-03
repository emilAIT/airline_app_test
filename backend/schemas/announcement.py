from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.announcement import AnnouncementType


class AnnouncementBase(BaseModel):
    flight_id: int
    announcement_type: AnnouncementType
    message: str


class AnnouncementCreate(AnnouncementBase):
    pass


class AnnouncementResponse(AnnouncementBase):
    id: int
    created_at: datetime
    flight: dict

    class Config:
        from_attributes = True

