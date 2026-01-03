from typing import Optional, List
from pydantic import BaseModel
from .seat import SeatMapTemplateResponse

class AirplaneBase(BaseModel):
    model: str
    total_seats: int


class AirplaneCreate(AirplaneBase):
    pass


class AirplaneResponse(AirplaneBase):
    id: int

    class Config:
        from_attributes = True

class AirplaneUpdate(BaseModel):
    model: Optional[str] = None

class AirplaneWithSeatMaps(AirplaneResponse):
    seat_map_templates: List[SeatMapTemplateResponse] = []