from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from app.database import get_db
from app.models.all_models import Flight, Airport, Seat
from app.schemas.schemas import FlightOut, FlightSearch, SeatMapResponse, SeatOut
from typing import List, Optional
from datetime import datetime, date

router = APIRouter(prefix="/flights", tags=["Flights"])


@router.get("/", response_model=List[FlightOut])
def get_flights(
    origin_id: Optional[int] = Query(None),
    destination_id: Optional[int] = Query(None),
    departure_date: Optional[date] = Query(None),
    db: Session = Depends(get_db)
):
    """Search flights with optional filters - excludes cancelled and departed flights"""
    from app.models.all_models import SeatHold, FlightStatus

    query = db.query(Flight)

    # Exclude cancelled and departed flights for passengers
    query = query.filter(
        Flight.status != FlightStatus.CANCELLED
    ).filter(
        Flight.status != FlightStatus.DEPARTED
    )

    if origin_id:
        query = query.filter(Flight.origin_id == origin_id)
    if destination_id:
        query = query.filter(Flight.destination_id == destination_id)
    if departure_date:
        # Filter by date (ignore time) - use UTC for consistency
        start_of_day = datetime.combine(departure_date, datetime.min.time())
        end_of_day = datetime.combine(departure_date, datetime.max.time())
        # Convert to UTC if needed
        start_of_day = start_of_day.replace(tzinfo=None)
        end_of_day = end_of_day.replace(tzinfo=None)
        query = query.filter(
            and_(
                Flight.departure_time >= start_of_day,
                Flight.departure_time <= end_of_day
            )
        )
    else:
        # If no specific date requested, show only future flights
        query = query.filter(Flight.departure_time > datetime.utcnow())

    flights = query.order_by(Flight.departure_time).all()

    # Calculate available seats for each flight
    now = datetime.utcnow()
    result = []
    for flight in flights:
        # Generate seats if they don't exist
        from app.services.seat_service import generate_seats_for_flight
        generate_seats_for_flight(db, flight)

        # Count available seats (not booked and not held)
        total_seats = db.query(Seat).filter(
            Seat.flight_id == flight.id).count()
        booked_seats = db.query(Seat).filter(
            Seat.flight_id == flight.id,
            Seat.is_available == False
        ).count()

        # Count held seats
        held_seats = db.query(SeatHold).filter(
            SeatHold.flight_id == flight.id,
            SeatHold.held_until > now
        ).count()

        available_seats = total_seats - booked_seats - held_seats

        # Create flight dict with available_seats
        flight_dict = {
            "id": flight.id,
            "flight_number": flight.flight_number,
            "origin": flight.origin,
            "destination": flight.destination,
            "airplane": flight.airplane,
            "departure_time": flight.departure_time,
            "arrival_time": flight.arrival_time,
            "base_price": flight.base_price,
            "status": flight.status,
            "gate": flight.gate,
            "terminal": flight.terminal,
            "available_seats": max(0, available_seats)
        }
        result.append(FlightOut(**flight_dict))

    return result


@router.get("/airports", response_model=List[dict])
def get_airports(db: Session = Depends(get_db)):
    """Get all airports"""
    airports = db.query(Airport).all()
    return [{"id": a.id, "code": a.code, "name": a.name, "city": a.city, "country": a.country} for a in airports]


@router.get("/{flight_id}", response_model=FlightOut)
def get_flight(flight_id: int, db: Session = Depends(get_db)):
    """Get flight details"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Flight not found")
    return flight


@router.get("/{flight_id}/seat-map", response_model=SeatMapResponse)
def get_seat_map(flight_id: int, db: Session = Depends(get_db)):
    """Get seat map for a flight"""
    from app.models.all_models import SeatHold
    from datetime import datetime

    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Flight not found")

    # Generate seats if they don't exist
    from app.services.seat_service import generate_seats_for_flight
    generate_seats_for_flight(db, flight)

    # Get all seats
    seats = db.query(Seat).filter(Seat.flight_id == flight_id).all()

    # Check which seats are held
    now = datetime.utcnow()
    held_seats = {
        sh.seat_number for sh in db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.held_until > now
        ).all()
    }

    # Mark held seats as unavailable in response
    seat_out_list = []
    for seat in seats:
        is_available = seat.is_available and seat.seat_number not in held_seats
        seat_out_list.append(SeatOut(
            id=seat.id,
            seat_number=seat.seat_number,
            category=seat.category,
            is_available=is_available,
            row=seat.row,
            column=seat.column
        ))

    available_count = sum(1 for s in seat_out_list if s.is_available)
    total_count = len(seat_out_list)

    return SeatMapResponse(
        flight_id=flight_id,
        seats=seat_out_list,
        available_count=available_count,
        total_count=total_count
    )
