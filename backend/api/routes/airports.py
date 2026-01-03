from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from schemas.airport import AirportResponse
from core.dependencies import get_db
from models.airport import Airport

router = APIRouter(
    prefix="/airports",
    tags=["Airports"],
)


@router.get(
    "/",
    response_model=List[AirportResponse],
)
def list_airports(
    db: Session = Depends(get_db),
):
    return db.query(Airport).all()