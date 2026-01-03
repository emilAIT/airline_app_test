from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from datetime import datetime, timedelta
import hashlib
from .. import models, schemas
from ..enums import BookingStatus


def check_in_ticket(db: Session, ticket_id: int) -> models.CheckIn:
    # Get ticket
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    # Check if already checked in
    existing_checkin = db.query(models.CheckIn).filter(models.CheckIn.ticket_id == ticket_id).first()
    if existing_checkin:
        return existing_checkin
    
    # Get booking and flight
    booking = ticket.booking
    flight = booking.flight
    
    # Check booking status
    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only confirmed bookings can be checked in"
        )
    
    # Check time window (24 hours to 1 hour before departure)
    now = datetime.utcnow()
    time_until_departure = (flight.departure_time - now).total_seconds() / 3600  # hours
    
    if time_until_departure > 24:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in opens 24 hours before departure"
        )
    
    if time_until_departure < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in closes 1 hour before departure"
        )
    
    # Generate QR code (simple hash for mock)
    qr_data = f"{flight.flight_number}:{ticket.passenger_name}:{ticket.seat_number}:{ticket.ticket_number}"
    qr_code = hashlib.sha256(qr_data.encode()).hexdigest()[:16]
    
    # Create check-in
    check_in = models.CheckIn(
        ticket_id=ticket_id,
        qr_code=qr_code
    )
    db.add(check_in)
    db.commit()
    db.refresh(check_in)
    
    return check_in


def get_boarding_pass(db: Session, ticket_id: int) -> dict:
    # Get ticket with check-in
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    check_in = db.query(models.CheckIn).filter(models.CheckIn.ticket_id == ticket_id).first()
    if not check_in:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ticket not checked in"
        )
    
    booking = ticket.booking
    flight = booking.flight
    
    return {
        "passenger_name": ticket.passenger_name,
        "flight_number": flight.flight_number,
        "seat_number": ticket.seat_number,
        "gate": flight.gate,
        "boarding_time": flight.boarding_time,
        "departure_time": flight.departure_time,
        "qr_code": check_in.qr_code
    }

