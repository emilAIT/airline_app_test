from pydantic import BaseModel


class AirportBase(BaseModel):
    code: str
    name: str
    city: str
    country: str


class AirportResponse(AirportBase):
    class Config:
        from_attributes = True
