"""Airports API (exam schema)."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.airport import Airport


router = APIRouter()


class AirportResponse(BaseModel):
    id: int
    code: str
    name: str
    city: str

    class Config:
        from_attributes = True


@router.get("", response_model=List[AirportResponse])
def list_airports(db: Session = Depends(get_db)):
    airports = db.query(Airport).order_by(Airport.code.asc()).all()
    return [AirportResponse.model_validate(a) for a in airports]


@router.get("/{code}", response_model=AirportResponse)
def get_airport(code: str, db: Session = Depends(get_db)):
    airport = db.query(Airport).filter(Airport.code == code.upper()).first()
    if not airport:
        raise HTTPException(status_code=404, detail="Airport not found")
    return AirportResponse.model_validate(airport)
