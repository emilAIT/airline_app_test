from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import qrcode
import io
import base64
from app.models.checkin import CheckIn
from app.models.booking import Ticket, Booking, BookingStatus
from app.models.flight import Flight
from fastapi import HTTPException, status


def generate_qr_code(ticket_number: str, pnr: str) -> str:
    """Generate QR code string payload"""
    payload = f"PNR:{pnr}|TICKET:{ticket_number}"
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(payload)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    return img_str


def check_in_ticket(
    db: Session,
    ticket_id: int,
    user_id: int
) -> CheckIn:
    """Check in a ticket"""
    # Get ticket
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    # Verify ticket belongs to user
    booking = db.query(Booking).filter(Booking.id == ticket.booking_id).first()
    if booking.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ticket does not belong to user"
        )
    
    # Check if booking is confirmed
    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only confirmed bookings can be checked in"
        )
    
    # Check if already checked in
    existing_checkin = db.query(CheckIn).filter(CheckIn.ticket_id == ticket_id).first()
    if existing_checkin:
        return existing_checkin
    
    # Get flight
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Check check-in window (opens 24 hours before departure, closes 1 hour before)
    # Note: Flight times are stored in local timezone (Asia/Bishkek), so use local time
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    departure = flight.departure_time
    
    check_in_open = departure - timedelta(hours=24)
    check_in_close = departure - timedelta(minutes=60)
    
    if now < check_in_open:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in opens 24 hours before departure"
        )
    
    if now > check_in_close:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Check-in closed. Check-in is available until 1 hour before departure."
        )
    
    # Create check-in
    qr_code = generate_qr_code(ticket.ticket_number, booking.pnr)
    check_in = CheckIn(
        ticket_id=ticket_id,
        checked_in_at=now,
        qr_code=qr_code
    )
    db.add(check_in)
    db.commit()
    db.refresh(check_in)
    return check_in

