from pydantic import BaseModel
from .flight import FlightOut
from .ticket import TicketOut

class BookingCreate(BaseModel):
    flight_id: int
    seats: list[str]

class BookingOut(BaseModel):
    id: int
    pnr_code: str
    status: str
    flight: FlightOut
    tickets: list[TicketOut]

    class Config:
        from_attributes = True
