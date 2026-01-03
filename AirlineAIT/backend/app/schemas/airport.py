from pydantic import BaseModel
from typing import Optional


class AirportCreate(BaseModel):
    code: str
    name: str
    city: str
    country: str


class AirportUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None


class AirportResponse(BaseModel):
    id: int
    code: str
    name: str
    city: str
    country: str

    class Config:
        from_attributes = True


