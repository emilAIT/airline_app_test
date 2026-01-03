from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from .. import schemas
from ..database import get_db
from ..services import flight_service

router = APIRouter(prefix="/flights", tags=["Flights"])


@router.get("/search", response_model=List[schemas.FlightSearchResponse])
def search_flights(
    origin: str = Query(..., description="Origin airport code"),
    destination: str = Query(..., description="Destination airport code"),
    departure_date: date = Query(..., description="Departure date"),
    db: Session = Depends(get_db)
):
    """Search flights by origin, destination, and date"""
    return flight_service.search_flights(db, origin, destination, departure_date)


@router.get("/{flight_id}", response_model=schemas.FlightDetailResponse)
def get_flight(flight_id: int, db: Session = Depends(get_db)):
    """Get detailed flight information"""
    flight = flight_service.get_flight_detail(db, flight_id)
    # Inject available_seats
    flight.available_seats = flight_service.get_available_seats_count(db, flight_id)
    return flight


@router.get("/{flight_id}/seats", response_model=schemas.SeatMapResponse)
def get_seat_map(flight_id: int, db: Session = Depends(get_db)):
    """Get seat map for a flight"""
    return flight_service.get_seat_map(db, flight_id)

