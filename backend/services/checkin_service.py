from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import datetime, timedelta
import random
import string
from app.models.checkin import CheckIn
from app.models.ticket import Ticket
from app.models.booking import Booking, BookingStatus


def generate_qr_code(ticket: Ticket) -> str:
    """
    Generate QR code payload for boarding pass.
    Simple string payload per instructions.txt line 233.
    """
    return f"TICKET-{ticket.ticket_number}-FLIGHT-{ticket.booking.flight.flight_number}-SEAT-{ticket.seat_number}"


def check_in_ticket(db: Session, ticket_id: int, user_id: int = None) -> CheckIn:
    """
    Check in a ticket.
    Per instructions.txt lines 224-233:
    - Allowed 24h to 1h before departure
    - Only CONFIRMED bookings
    - Per ticket (per passenger)
    """
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    # Check authorization
    if user_id and ticket.booking.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to check in this ticket"
        )
    
    # Check if already checked in
    if ticket.checkin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ticket already checked in"
        )
    
    # Check booking status
    if ticket.booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only confirmed bookings can be checked in"
        )
    
    # Check time window: 24h to 1h before departure
    now = datetime.utcnow()
    departure = ticket.booking.flight.scheduled_departure
    time_until_departure = departure - now
    
    if time_until_departure > timedelta(hours=24):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in opens 24 hours before departure"
        )
    
    if time_until_departure < timedelta(hours=1):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in closes 1 hour before departure"
        )
    
    # Generate QR code
    qr_code = generate_qr_code(ticket)
    
    # Boarding time: typically 30-45 minutes before departure
    boarding_time = departure - timedelta(minutes=40)
    
    # Create check-in record
    checkin = CheckIn(
        ticket_id=ticket_id,
        qr_code=qr_code,
        boarding_time=boarding_time
    )
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    
    return checkin


def get_boarding_pass(db: Session, ticket_id: int, user_id: int = None) -> dict:
    """
    Get boarding pass information for a ticket.
    Per instructions.txt lines 227-233, includes:
    - Passenger name
    - Flight number
    - Seat
    - Gate
    - Boarding time
    - QR code
    """
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    # Check authorization
    if user_id and ticket.booking.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this boarding pass"
        )
    
    # Check if checked in
    if not ticket.checkin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ticket not checked in. Please check in first."
        )
    
    flight = ticket.booking.flight
    passenger = ticket.passenger
    
    boarding_pass = {
        "passenger_name": f"{passenger.first_name} {passenger.last_name}",
        "flight_number": flight.flight_number,
        "seat": ticket.seat_number,
        "gate": flight.gate or "TBD",
        "boarding_time": ticket.checkin.boarding_time,
        "departure_time": flight.scheduled_departure,
        "origin": flight.origin_airport.code,
        "destination": flight.destination_airport.code,
        "qr_code": ticket.checkin.qr_code,
        "ticket_number": ticket.ticket_number,
        "pnr": ticket.booking.pnr
    }
    
    return boarding_pass
