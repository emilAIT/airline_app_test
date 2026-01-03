from pydantic import BaseModel
from datetime import datetime


class AnnouncementCreate(BaseModel):
    flight_id: int | None = None
    type: str
    title: str
    message: str


class AnnouncementResponse(BaseModel):
    id: int
    flight_id: int | None = None
    type: str
    title: str
    message: str
    created_at: datetime

    class Config:
        from_attributes = True
