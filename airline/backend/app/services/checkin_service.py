from sqlalchemy.orm import Session
from app.models.all_models import CheckIn, Ticket, Booking, BookingStatus, Flight
from datetime import datetime, timedelta
import json


def can_check_in(flight: Flight) -> bool:
    """Check if check-in is allowed (24 hours to 1 hour before departure)"""
    now = datetime.utcnow()
    time_until_departure = flight.departure_time - now

    # Check-in allowed from 24 hours to 1 hour before departure
    min_time = timedelta(hours=1)
    max_time = timedelta(hours=24)

    return min_time <= time_until_departure <= max_time


def create_check_in(db: Session, ticket_id: int) -> CheckIn:
    """Create a check-in record"""
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise ValueError("Ticket not found")

    booking = ticket.booking
    if booking.status != BookingStatus.CONFIRMED:
        raise ValueError("Only confirmed bookings can be checked in")

    flight = booking.flight
    if not can_check_in(flight):
        raise ValueError("Check-in is only allowed 24 hours to 1 hour before departure")

    # Check if already checked in
    existing_checkin = db.query(CheckIn).filter(CheckIn.ticket_id == ticket_id).first()
    if existing_checkin:
        return existing_checkin

    # Generate QR code payload
    qr_payload = json.dumps({
        "ticket_number": ticket.ticket_number,
        "flight_number": flight.flight_number,
        "passenger_name": ticket.passenger_name,
        "seat": ticket.seat_number
    })

    check_in = CheckIn(
        ticket_id=ticket_id,
        boarding_time=flight.departure_time - timedelta(minutes=30),  # 30 min before departure
        gate=flight.gate,
        qr_code=qr_payload
    )
    db.add(check_in)
    db.commit()
    db.refresh(check_in)
    return check_in


def get_boarding_pass(db: Session, ticket_id: int) -> dict:
    """Get boarding pass information"""
    check_in = db.query(CheckIn).filter(CheckIn.ticket_id == ticket_id).first()
    if not check_in:
        raise ValueError("Ticket not checked in")

    ticket = check_in.ticket
    flight = ticket.booking.flight

    return {
        "passenger_name": ticket.passenger_name,
        "flight_number": flight.flight_number,
        "seat": ticket.seat_number,
        "gate": check_in.gate or flight.gate,
        "boarding_time": check_in.boarding_time,
        "qr_code": check_in.qr_code
    }

