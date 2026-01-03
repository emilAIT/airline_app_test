from sqlalchemy.orm import Session
from app.models.all_models import Booking, Ticket, BookingStatus, Flight, Seat, Notification
from app.services.seat_service import hold_seat, mark_seat_unavailable, auto_assign_seat, cleanup_expired_holds
from datetime import datetime, timedelta, timezone
import random
import string


def generate_pnr() -> str:
    """Generate a unique 6-character PNR code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


def generate_ticket_number() -> str:
    """Generate a unique ticket number"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))


def create_booking(
    db: Session,
    user_id: int,
    flight_id: int,
    tickets_data: list,
    hold_seats: bool = True
) -> Booking:
    """Create a booking with tickets"""
    cleanup_expired_holds(db)

    # Check flight exists and is not cancelled/departed
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise ValueError("Flight not found")
    if flight.status in ["CANCELLED", "DEPARTED"]:
        raise ValueError("Cannot book cancelled or departed flights")

    # Generate unique PNR
    pnr = generate_pnr()
    while db.query(Booking).filter(Booking.pnr == pnr).first():
        pnr = generate_pnr()

    booking = Booking(
        pnr=pnr,
        user_id=user_id,
        flight_id=flight_id,
        status=BookingStatus.CREATED,
        hold_until=datetime.now(timezone.utc) + timedelta(minutes=10)  # 10-min hold
    )
    db.add(booking)
    db.flush()

    # Create tickets and hold seats
    for ticket_data in tickets_data:
        seat_number = ticket_data.get("seat_number")
        if not seat_number:
            # Auto-assign seat
            seat_number = auto_assign_seat(db, flight_id)
            if not seat_number:
                db.rollback()
                raise ValueError("No available seats")

        if hold_seats:
            try:
                hold_seat(db, flight_id, seat_number, booking.id)
            except ValueError as e:
                db.rollback()
                raise ValueError(f"Cannot hold seat {seat_number}: {str(e)}")

        ticket_number = generate_ticket_number()
        while db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first():
            ticket_number = generate_ticket_number()

        ticket = Ticket(
            booking_id=booking.id,
            seat_number=seat_number,
            passenger_name=ticket_data["passenger_name"],
            ticket_number=ticket_number
        )
        db.add(ticket)

    db.commit()
    db.refresh(booking)
    return booking


def confirm_booking(db: Session, booking_id: int):
    """Confirm booking after payment - mark seats as unavailable"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    # Mark all seats as unavailable
    for ticket in booking.tickets:
        mark_seat_unavailable(db, booking.flight_id, ticket.seat_number)

    booking.status = BookingStatus.CONFIRMED
    booking.hold_until = None  # Clear timer on payment
    db.commit()
    return booking


def expire_bookings(db: Session) -> int:
    """Mark bookings as EXPIRED if hold_until has passed and create notifications"""
    now = datetime.now(timezone.utc)
    expired = db.query(Booking).filter(
        Booking.status == BookingStatus.CREATED,
        Booking.hold_until < now
    ).all()
    
    for booking in expired:
        booking.status = BookingStatus.EXPIRED
        # Create notification for user
        notification = Notification(
            user_id=booking.user_id,
            message="Payment time expired. Your reservation has been cancelled."
        )
        db.add(notification)
    
    db.commit()
    # Also cleanup seat holds
    cleanup_expired_holds(db)
    return len(expired)


def cancel_booking(db: Session, booking_id: int):
    """Cancel a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    booking.status = BookingStatus.CANCELLED
    # Release seats (mark as available again)
    for ticket in booking.tickets:
        seat = db.query(Seat).filter(
            Seat.flight_id == booking.flight_id,
            Seat.seat_number == ticket.seat_number
        ).first()
        if seat:
            seat.is_available = True
    db.commit()
    return booking

