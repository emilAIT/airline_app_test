"""
Flights API routes.

Endpoints:
- GET /airports: List all airports
- GET /search: Search flights with filters
- GET /{flight_id}: Get flight details
- GET /{flight_id}/seat-map: Get seat availability

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from datetime import datetime, date
from typing import Optional, List
from app.db.session import get_db
from app.api.deps import get_current_passenger
from app.models.user import User
from app.models.flight import Flight
from app.models.airport import Airport
from app.schemas.flight import FlightResponse, FlightDetailResponse, SeatMapResponse
from app.schemas.airport import AirportResponse
from app.services.seat_hold import get_available_seats, release_expired_holds
from app.api.routes.staff import update_flight_status_based_on_time

router = APIRouter(prefix="/flights", tags=["Flights"])


@router.get("/airports", response_model=List[AirportResponse])
def list_airports(db: Session = Depends(get_db)):
    """List all available airports"""
    airports = db.query(Airport).all()
    return airports


@router.get("/search", response_model=List[FlightResponse])
def search_flights(
    origin_airport_id: Optional[int] = Query(None),
    destination_airport_id: Optional[int] = Query(None),
    departure_date: Optional[date] = Query(None),
    db: Session = Depends(get_db)
):
    """Search flights"""
    query = db.query(Flight)
    
    if origin_airport_id:
        query = query.filter(Flight.origin_airport_id == origin_airport_id)
    
    if destination_airport_id:
        query = query.filter(Flight.destination_airport_id == destination_airport_id)
    
    if departure_date:
        start_datetime = datetime.combine(departure_date, datetime.min.time())
        end_datetime = datetime.combine(departure_date, datetime.max.time())
        query = query.filter(
            Flight.departure_time >= start_datetime,
            Flight.departure_time <= end_datetime
        )
    
    flights = query.all()
    
    # Run auto-status update on all fetched flights
    updates = False
    for flight in flights:
        if update_flight_status_based_on_time(flight, db):
            updates = True
            
    if updates:
        db.commit()
    
    # Add duration to each flight
    result = []
    for flight in flights:
        flight_data = FlightResponse.model_validate(flight).model_dump()
        if flight.departure_time and flight.arrival_time:
            duration = int((flight.arrival_time - flight.departure_time).total_seconds() / 60)
            flight_data['duration_minutes'] = duration
        result.append(FlightResponse(**flight_data))
    return result


@router.get("/{flight_id}", response_model=FlightDetailResponse)
def get_flight_details(
    flight_id: int,
    db: Session = Depends(get_db)
):
    """Get flight details"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Run auto-status update
    if update_flight_status_based_on_time(flight, db):
        db.commit()
        db.refresh(flight)
    
    # Get available seats count
    seat_map_resp = get_available_seats(db, flight_id, include_held=False)
    seat_map = seat_map_resp["seat_map"]
    available_count = sum(1 for seat_info in seat_map.values() if seat_info["available"])
    
    # Build response
    origin_airport = db.query(Airport).filter(Airport.id == flight.origin_airport_id).first()
    destination_airport = db.query(Airport).filter(Airport.id == flight.destination_airport_id).first()
    
    from app.models.airplane import Airplane
    airplane = db.query(Airplane).filter(Airplane.id == flight.airplane_id).first()
    
    flight_response = FlightResponse.model_validate(flight)
    return {
        **flight_response.model_dump(),
        "origin_airport": {
            "id": origin_airport.id,
            "code": origin_airport.code,
            "name": origin_airport.name,
            "city": origin_airport.city,
            "country": origin_airport.country
        },
        "destination_airport": {
            "id": destination_airport.id,
            "code": destination_airport.code,
            "name": destination_airport.name,
            "city": destination_airport.city,
            "country": destination_airport.country
        },
        "airplane": {
            "id": airplane.id,
            "model": airplane.model,
            "registration_number": airplane.registration_number
        },
        "available_seats": available_count
    }


@router.get("/{flight_id}/seat-map", response_model=SeatMapResponse)
def get_seat_map(
    flight_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_passenger)
):
    """Get seat map for a flight"""
    # Release expired holds first
    release_expired_holds(db)
    
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    
    # Run auto-status update
    if update_flight_status_based_on_time(flight, db):
        db.commit()
        db.refresh(flight)
    
    # Check if user is staff or admin to show passenger names
    from app.models.user import UserRole
    show_passenger_info = current_user is not None and current_user.role in [UserRole.ADMIN, UserRole.STAFF]
    
    seat_map_resp = get_available_seats(db, flight_id, include_held=True, include_passenger_info=show_passenger_info)
    return {
        "flight_id": flight_id,
        "seat_map": seat_map_resp["seat_map"],
        "template": seat_map_resp["template"]
    }

