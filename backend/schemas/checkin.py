from pydantic import BaseModel
from datetime import datetime


class CheckInResponse(BaseModel):
    ticket_id: int
    boarding_pass_qr: str
    checked_in: bool
    checked_in_at: datetime

    class Config:
        from_attributes = True
