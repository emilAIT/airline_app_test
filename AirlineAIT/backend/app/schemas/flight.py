from pydantic import BaseModel, field_validator
from datetime import datetime
from typing import Optional, List, Dict, Any
from app.models.flight import FlightStatus
from app.schemas.airport import AirportResponse


class FlightSearch(BaseModel):
    origin_airport_id: Optional[int] = None
    destination_airport_id: Optional[int] = None
    departure_date: Optional[datetime] = None


class FlightResponse(BaseModel):
    id: int
    flight_number: str
    origin_airport_id: int
    destination_airport_id: int
    airplane_id: int
    departure_time: datetime
    arrival_time: datetime
    price: float
    category_prices: Optional[Dict[str, float]] = None
    category_allocations: Optional[Dict[str, Dict[str, int]]] = None
    gate: Optional[str]
    terminal: Optional[str]
    status: str
    origin_airport: Optional[AirportResponse] = None
    destination_airport: Optional[AirportResponse] = None
    duration_minutes: Optional[int] = None  # Calculated duration in minutes
    
    class Config:
        from_attributes = True
    
    @classmethod
    def from_orm_with_duration(cls, flight):
        """Create response with calculated duration"""
        duration = None
        if flight.departure_time and flight.arrival_time:
            duration = int((flight.arrival_time - flight.departure_time).total_seconds() / 60)
        data = cls.model_validate(flight).model_dump()
        data['duration_minutes'] = duration
        return cls(**data)
    
    @field_validator('category_prices', 'category_allocations', mode='before')
    @classmethod
    def parse_json_fields(cls, v):
        if isinstance(v, str):
            import json
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return None
        return v


class FlightDetailResponse(FlightResponse):
    airplane: Dict[str, Any]
    available_seats: int


class SeatMapResponse(BaseModel):
    flight_id: int
    seat_map: Dict[str, Any]  # {seat_number: {available: bool, category: str, held_until: Optional[datetime]}}
    template: Dict[str, Any]


class FlightCreate(BaseModel):
    flight_number: str
    origin_airport_id: int
    destination_airport_id: int
    airplane_id: int
    departure_time: datetime
    arrival_time: datetime
    price: float
    category_prices: Optional[Dict[str, float]] = None
    category_allocations: Optional[Dict[str, Dict[str, int]]] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None
    status: FlightStatus = FlightStatus.SCHEDULED


class FlightUpdate(BaseModel):
    airplane_id: Optional[int] = None
    departure_time: Optional[datetime] = None
    arrival_time: Optional[datetime] = None
    price: Optional[float] = None
    category_prices: Optional[Dict[str, float]] = None
    category_allocations: Optional[Dict[str, Dict[str, int]]] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None
    status: Optional[FlightStatus] = None

