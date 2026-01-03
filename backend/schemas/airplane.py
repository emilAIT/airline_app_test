from pydantic import BaseModel
from typing import Dict, Any


class AirplaneBase(BaseModel):
    model: str
    registration_number: str
    seat_template: Dict[str, Any]
    total_seats: int


class AirplaneCreate(AirplaneBase):
    pass


class AirplaneResponse(AirplaneBase):
    id: int

    class Config:
        from_attributes = True

