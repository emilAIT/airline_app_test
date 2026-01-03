"""
Check-in API routes.

Endpoints:
- POST /ticket/{ticket_id}: Check in for a ticket
- GET /ticket/{ticket_id}/boarding-pass: Get boarding pass

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_passenger
from app.models.user import User
from app.models.booking import Ticket
from app.schemas.checkin import CheckInResponse, BoardingPassResponse
from app.services.checkin import check_in_ticket

router = APIRouter(prefix="/checkin", tags=["Check-in"])


@router.post("/ticket/{ticket_id}", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
def check_in(
    ticket_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Check in for a ticket"""
    check_in = check_in_ticket(db, ticket_id, current_user.id)
    return check_in


@router.get("/ticket/{ticket_id}/boarding-pass", response_model=BoardingPassResponse)
def get_boarding_pass(
    ticket_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get boarding pass for a checked-in ticket"""
    # Get ticket
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    # Verify ownership
    from app.models.booking import Booking
    booking = db.query(Booking).filter(Booking.id == ticket.booking_id).first()
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized"
        )
    
    # Get check-in
    from app.models.checkin import CheckIn
    check_in = db.query(CheckIn).filter(CheckIn.ticket_id == ticket_id).first()
    if not check_in:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ticket not checked in"
        )
    
    # Get flight info
    from app.models.flight import Flight
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    
    # Get airport info
    from app.models.airport import Airport
    departure_airport = db.query(Airport).filter(Airport.id == flight.origin_airport_id).first()
    arrival_airport = db.query(Airport).filter(Airport.id == flight.destination_airport_id).first()
    
    # Get passenger name and info
    from app.models.passenger import PassengerProfile
    passenger = db.query(PassengerProfile).filter(
        PassengerProfile.id == ticket.passenger_profile_id
    ).first()
    
    # Calculate boarding time (60 minutes before departure)
    from datetime import timedelta
    boarding_time = flight.departure_time - timedelta(minutes=60)
    
    return {
        "passenger_name": passenger.full_name,
        "passenger_nationality": getattr(passenger, 'nationality', None),
        "passenger_passport_number": getattr(passenger, 'passport_number', None),
        "flight_number": flight.flight_number,
        "seat": ticket.seat_number,
        "gate": flight.gate,
        "terminal": getattr(flight, 'terminal', None),
        "boarding_time": boarding_time,
        "departure_time": flight.departure_time,
        "arrival_time": flight.arrival_time,
        "departure_airport_code": departure_airport.code,
        "departure_airport_name": departure_airport.name,
        "arrival_airport_code": arrival_airport.code,
        "arrival_airport_name": arrival_airport.name,
        "qr_code": check_in.qr_code
    }

