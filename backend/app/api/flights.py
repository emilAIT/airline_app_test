"""Flights API (exam schema)."""

from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.airport import Airport
from app.models.flight import Flight
from app.models.seat import Seat
from app.repositories.seat_hold import seat_hold_repository


router = APIRouter()


class FlightResponse(BaseModel):
    id: int
    flight_number: str
    origin_id: int
    destination_id: int
    departure_time: str
    arrival_time: str
    price: float
    status: str
    terminal: Optional[str] = None
    gate: Optional[str] = None
    airplane_id: Optional[int] = None
    airplane_model: Optional[str] = None
    airplane_registration: Optional[str] = None


class SeatResponse(BaseModel):
    id: int
    flight_id: int
    code: str
    seat_class: str
    is_occupied: bool
    price_markup: float


@router.get("", response_model=List[FlightResponse])
def list_flights(
    origin_id: Optional[int] = Query(None),
    destination_id: Optional[int] = Query(None),
    date_: Optional[date] = Query(None, alias="date"),
    departure_date: Optional[date] = Query(None, alias="departure_date"),
    db: Session = Depends(get_db),
):
    query = db.query(Flight)

    # Do not show flights that already departed.
    query = query.filter(Flight.departure_time >= datetime.utcnow())

    if origin_id is not None:
        query = query.filter(Flight.origin_id == origin_id)
    if destination_id is not None:
        query = query.filter(Flight.destination_id == destination_id)
    effective_date = date_ or departure_date
    if effective_date is not None:
        start = datetime.combine(effective_date, datetime.min.time())
        end = start + timedelta(days=1)
        query = query.filter(Flight.departure_time >= start).filter(Flight.departure_time < end)

    flights = query.order_by(Flight.departure_time.asc()).all()

    return [
        FlightResponse(
            id=f.id,
            flight_number=f.flight_number,
            origin_id=f.origin_id,
            destination_id=f.destination_id,
            departure_time=f.departure_time.isoformat(),
            arrival_time=f.arrival_time.isoformat(),
            price=float(f.price),
            status=f.status,
            terminal=f.terminal,
            gate=f.gate,
            airplane_id=f.airplane_id,
            airplane_model=f.airplane.model if f.airplane else None,
            airplane_registration=f.airplane.registration_number if f.airplane else None,
        )
        for f in flights
    ]


@router.get("/{flight_id}", response_model=FlightResponse)
def get_flight(flight_id: int, db: Session = Depends(get_db)):
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    return FlightResponse(
        id=flight.id,
        flight_number=flight.flight_number,
        origin_id=flight.origin_id,
        destination_id=flight.destination_id,
        departure_time=flight.departure_time.isoformat(),
        arrival_time=flight.arrival_time.isoformat(),
        price=float(flight.price),
        status=flight.status,
        airplane_id=flight.airplane_id,
        airplane_model=flight.airplane.model if flight.airplane else None,
        airplane_registration=flight.airplane.registration_number if flight.airplane else None,
        terminal=flight.terminal,
        gate=flight.gate,
    )


@router.get("/{flight_id}/seats", response_model=List[SeatResponse])
def get_flight_seats(flight_id: int, db: Session = Depends(get_db)):
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    if not flight.airplane_id:
        # No airplane assigned - return empty seats
        return []

    # Get seats from airplane
    from app.models.seat import Seat
    seats = db.query(Seat).filter(Seat.airplane_id == flight.airplane_id).order_by(
        Seat.row_number, Seat.seat_letter
    ).all()
    
    # Get occupied seats (tickets for this flight)
    from app.models.ticket import Ticket
    occupied_seat_ids = {
        t.seat_id for t in db.query(Ticket).filter(Ticket.flight_id == flight_id).all()
        if t.seat_id
    }
    
    return [
        SeatResponse(
            id=s.id,
            flight_id=flight_id,
            code=f"{s.row_number}{s.seat_letter}",
            seat_class=s.category.upper(),
            is_occupied=(s.id in occupied_seat_ids),
            price_markup=0.0,  # No markup needed, price is in flight
        )
        for s in seats
    ]
