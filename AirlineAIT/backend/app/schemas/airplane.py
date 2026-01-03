from typing import Dict, Any, List, Optional
import json
from pydantic import BaseModel, computed_field, field_validator


class SeatTemplateCreate(BaseModel):
    name: str
    rows: int
    seats_per_row: int
    seat_labels: List[str]
    seat_categories: Dict[str, str]  # e.g., {"1-5": "EXTRA_LEGROOM", "6-30": "STANDARD"}
    class_layouts: Optional[Dict[str, Dict[str, int]]] = None
    aisle_positions: Optional[List[int]] = []
    emergency_exits: Optional[List[int]] = []


class SeatTemplateResponse(BaseModel):
    id: int
    name: str
    rows: int
    seats_per_row: int
    seat_labels: List[str]
    seat_categories: Dict[str, str]
    class_layouts: Optional[Dict[str, Dict[str, int]]] = None
    aisle_positions: List[int]
    emergency_exits: List[int]
    
    @computed_field
    @property
    def capacity(self) -> int:
        if self.class_layouts:
            total = 0
            for layout in self.class_layouts.values():
                total += layout.get("rows", 0) * layout.get("seats_per_row", 0)
            return total
        return self.rows * self.seats_per_row

    @field_validator('seat_labels', 'seat_categories', 'class_layouts', 'aisle_positions', 'emergency_exits', mode='before')
    @classmethod
    def parse_json(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return v
        return v

    model_config = {"from_attributes": True}


class AirplaneCreate(BaseModel):
    model: str
    registration_number: str
    seat_template_id: int
    status: Optional[str] = "ACTIVE"


class AirplaneUpdate(BaseModel):
    status: Optional[str] = None


class AirplaneResponse(BaseModel):
    id: int
    model: str
    registration_number: str
    seat_template_id: int
    status: str
    seat_template: Optional[SeatTemplateResponse] = None
    
    @computed_field
    @property
    def capacity(self) -> int:
        if self.seat_template:
            return self.seat_template.capacity
        return 0

    model_config = {"from_attributes": True}

