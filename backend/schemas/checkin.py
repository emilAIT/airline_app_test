from pydantic import BaseModel
from datetime import datetime


class CheckInResponse(BaseModel):
    id: int
    ticket_id: int
    qr_code: str
    checked_in_at: datetime
    ticket: dict
    flight: dict

    class Config:
        from_attributes = True

