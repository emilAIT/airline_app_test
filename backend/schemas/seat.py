from pydantic import BaseModel
from typing import Literal
from typing import List

class SeatTemplateItem(BaseModel):
    row: int
    label: str 
    category: Literal[
        "STANDARD",
        "EXTRA_LEGROOM"
    ]

class SeatMapTemplateCreate(BaseModel):
    airplane_id: int
    seats: List[SeatTemplateItem]

class SeatMapTemplateResponse(BaseModel):
    id: int
    airplane_id: int
    seats: List[SeatTemplateItem]
    total_seats_count: int

    class Config:
        from_attributes = True

class SeatMapTemplatePreviewResponse(BaseModel):
    id: int
    airplane_id: int
    preview: str
