from pydantic import BaseModel

class TicketOut(BaseModel):
    id: int
    passenger_name: str
    passport_number: str | None = None
    nationality: str | None = None
    seat_number: str
    ticket_number: str

    class Config:
        from_attributes = True
