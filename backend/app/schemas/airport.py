"""
Airport schemas for request/response validation.
"""
from pydantic import BaseModel, Field


class AirportResponse(BaseModel):
    """Airport response."""
    id: int
    code: str = Field(max_length=3)  # IATA code
    name: str
    city: str
    country: str
    timezone: str | None
    
    class Config:
        from_attributes = True
