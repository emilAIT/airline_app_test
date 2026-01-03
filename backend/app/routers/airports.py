from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from .. import schemas
from ..database import get_db
from ..services import flight_service

router = APIRouter(prefix="/airports", tags=["Airports"])


@router.get("/", response_model=List[schemas.AirportResponse])
def get_airports(db: Session = Depends(get_db)):
    """Get all airports"""
    return flight_service.get_all_airports(db)

