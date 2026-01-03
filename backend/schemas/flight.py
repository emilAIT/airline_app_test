from pydantic import BaseModel, Field
from datetime import datetime
# from typing import Optional

class FlightOut(BaseModel):
    id: int
    flight_number: str
    origin_code: str
    destination_code: str
    departure_time: datetime
    arrival_time: datetime
    price: float
    status: str

    class Config:
        from_attributes = True


# class FlightBase(BaseModel):
#     flight_number: str

#     origin_id: int
#     destination_id: int

#     departure_time: datetime
#     arrival_time: datetime

#     price: float

#     status: str

#     airplane_id: Optional[int] = None
#     gate: Optional[str] = None
#     terminal: Optional[str] = None

# class FlightSearchRequest(BaseModel):
#     origin_code: str
#     destination_code: str
#     departure_date: datetime

# class FlightSearchResponse(BaseModel):
#     flight_number: str
#     departure_time: datetime
#     arrival_time: datetime
#     duration_minutes: int
#     price: float
#     available_seats: int
#     status: str

# class FlightCreate(BaseModel):
#     flight_number: str
#     origin_code: str
#     destination_code: str
#     departure_time: datetime
#     arrival_time: datetime
#     price: float

# class FlightAssignAirplane(BaseModel):
#     airplane_id: int

# class FlightScheduleUpdate(BaseModel):
#     departure_time: Optional[datetime] = None
#     arrival_time: Optional[datetime] = None

# class FlightGateUpdate(BaseModel):
#     gate: str

# class FlightTerminalUpdate(BaseModel):
#     terminal: str

# class FlightStatusUpdate(BaseModel):
#     status: str = Field(
#         ...,
#         examples=["SCHEDULED", "BOARDING", "DELAYED", "CANCELLED", "LANDED"]
#     )

# class FlightResponse(FlightBase):
#     id: int

#     class Config:
#         from_attributes = True