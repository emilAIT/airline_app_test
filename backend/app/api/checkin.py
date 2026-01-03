"""
Check-in API routes - passenger check-in and boarding pass generation.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.checkin import CheckIn
from app.models.ticket import Ticket
from app.models.booking import Booking
from app.models.flight import Flight
from app.core.exceptions import NotFound, ValidationError


router = APIRouter()


# ==================== SCHEMAS ====================

class CheckInRequest(BaseModel):
    """Check-in request schema."""
    ticket_number: str


class CheckInResponse(BaseModel):
    """Check-in response with boarding pass."""
    id: int
    ticket_id: int
    ticket_number: str
    passenger_name: str
    flight_number: str
    seat_number: str
    gate: Optional[str] = None
    boarding_time: str
    boarding_pass_qr: str
    checked_in_at: str
    
    class Config:
        from_attributes = True


# ==================== CHECK-IN ====================

@router.post("", response_model=CheckInResponse, status_code=201)
def check_in_passenger(
    data: CheckInRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Perform passenger check-in.
    
    **Business Rules:**
        1. Check-in window: 24 hours to 1 hour before departure
        2. Only CONFIRMED bookings can check-in
        3. One check-in per ticket (unique constraint enforced)
        4. Generates QR code string for boarding pass
    
    **QR Code Format:**
        "QR:{flight_number}:{seat_number}:{ticket_number}"
        
    Example:
        "QR:KC101:12A:7841234567890"
    
    Returns:
        CheckInResponse with boarding pass QR code
    
    Raises:
        NotFound: Ticket not found or not owned by user
        ValidationError: Check-in window not open, booking not confirmed, or already checked in
    """
    # Find ticket by number
    ticket = db.query(Ticket).filter(Ticket.ticket_number == data.ticket_number).first()
    
    if not ticket:
        raise NotFound("Ticket")
    
    # Get booking to verify ownership and status
    booking = db.query(Booking).filter(Booking.id == ticket.booking_id).first()
    
    if not booking:
        raise NotFound("Booking")
    
    # Verify ownership (passengers can only check-in their own tickets)
    if current_user.role == "PASSENGER" and booking.user_id != current_user.id:
        raise NotFound("Ticket")  # Don't reveal ticket exists
    
    # Verify booking is CONFIRMED
    if booking.status != "CONFIRMED":
        raise ValidationError(f"Cannot check-in: booking status is {booking.status}. Only CONFIRMED bookings can check-in.")
    
    # Get flight details
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    
    if not flight:
        raise NotFound("Flight")
    
    # ===== CHECK-IN WINDOW VALIDATION =====
    # Window: 24 hours before departure to 1 hour before departure
    now = datetime.utcnow()
    checkin_opens = flight.departure_time - timedelta(hours=24)
    checkin_closes = flight.departure_time - timedelta(hours=1)
    
    if now < checkin_opens:
        hours_until_open = int((checkin_opens - now).total_seconds() / 3600)
        raise ValidationError(
            f"Check-in not yet available. Opens 24 hours before departure (in {hours_until_open} hours)."
        )
    
    if now > checkin_closes:
        raise ValidationError(
            "Check-in window closed. Check-in closes 1 hour before departure."
        )
    
    # Verify not already checked in
    existing_checkin = db.query(CheckIn).filter(CheckIn.ticket_id == ticket.id).first()
    if existing_checkin:
        raise ValidationError("Ticket already checked in")
    
    # Generate QR code string
    # Format: "QR:{flight_number}:{seat_number}:{ticket_number}"
    qr_code = f"QR:{flight.flight_number}:{ticket.seat_number}:{ticket.ticket_number}"
    
    # Create check-in record
    checkin = CheckIn(
        ticket_id=ticket.id,
        boarding_pass_qr=qr_code
    )
    
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    
    # Build response
    passenger_name = f"{ticket.passenger_first_name} {ticket.passenger_last_name}"
    
    return CheckInResponse(
        id=checkin.id,
        ticket_id=checkin.ticket_id,
        ticket_number=ticket.ticket_number,
        passenger_name=passenger_name,
        flight_number=flight.flight_number,
        seat_number=ticket.seat_number,
        gate=flight.gate,
        boarding_time=(flight.departure_time - timedelta(minutes=30)).isoformat(),
        boarding_pass_qr=checkin.boarding_pass_qr,
        checked_in_at=checkin.checked_in_at.isoformat()
    )


@router.get("/ticket/{ticket_number}", response_model=CheckInResponse)
def get_boarding_pass(
    ticket_number: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieve boarding pass for a checked-in ticket.
    
    Returns QR code and boarding details if already checked in.
    
    Raises:
        NotFound: Ticket not found or not checked in
    """
    # Find ticket
    ticket = db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first()
    
    if not ticket:
        raise NotFound("Ticket")
    
    # Verify ownership
    booking = db.query(Booking).filter(Booking.id == ticket.booking_id).first()
    if current_user.role == "PASSENGER" and booking.user_id != current_user.id:
        raise NotFound("Ticket")
    
    # Get check-in
    checkin = db.query(CheckIn).filter(CheckIn.ticket_id == ticket.id).first()
    
    if not checkin:
        raise NotFound("Check-in not found. Passenger has not checked in yet.")
    
    # Get flight details
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    passenger_name = f"{ticket.passenger_first_name} {ticket.passenger_last_name}"
    
    return CheckInResponse(
        id=checkin.id,
        ticket_id=checkin.ticket_id,
        ticket_number=ticket.ticket_number,
        passenger_name=passenger_name,
        flight_number=flight.flight_number,
        seat_number=ticket.seat_number,
        gate=flight.gate,
        boarding_time=(flight.departure_time - timedelta(minutes=30)).isoformat(),
        boarding_pass_qr=checkin.boarding_pass_qr,
        checked_in_at=checkin.checked_in_at.isoformat()
    )
