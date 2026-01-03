from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

from schemas.seat import SeatTemplateItem

class FlightDetailsResponse(BaseModel):
    flight_number: str

    route: str
    aircraft: Optional[str]

    departure_time: datetime
    arrival_time: datetime

    status: str
    gate: Optional[str]
    terminal: Optional[str]

    seat_map: Optional[List[SeatTemplateItem]]
