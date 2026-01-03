from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
from datetime import datetime, timedelta
import string
import random
from app.models.booking import Booking, BookingStatus
from app.models.seat_hold import SeatHold
from app.models.ticket import Ticket
from app.models.payment import Payment, PaymentStatus
from app.models.flight import Flight
from app.models.passenger_profile import PassengerProfile


def generate_pnr() -> str:
    """Generate a unique 6-character PNR"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


def generate_ticket_number() -> str:
    """Generate a unique ticket number"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))


def cleanup_expired_holds(db: Session, flight_id: int):
    """
    Lazy cleanup of expired seat holds for a flight.
    Called during booking creation and seat availability queries.
    No background workers - per instructions.txt line 109
    """
    now = datetime.utcnow()
    expired_holds = db.query(SeatHold).filter(
        SeatHold.flight_id == flight_id,
        SeatHold.held_until < now
    ).all()
    
    for hold in expired_holds:
        db.delete(hold)
    
    # Also cancel bookings with expired holds
    expired_bookings = db.query(Booking).filter(
        Booking.flight_id == flight_id,
        Booking.status == BookingStatus.CREATED,
        Booking.held_until < now
    ).all()
    
    for booking in expired_bookings:
        booking.status = BookingStatus.CANCELLED
    
    db.flush()


def create_booking(
    db: Session,
    user_id: int,
    flight_id: int,
    passenger_data_list: list  # [{"passenger_profile_id": int, "seat_number": str, "seat_category": str}]
) -> Booking:
    """
    Create a booking with seat holds.
    Uses SQLite-safe transaction and UNIQUE constraints to prevent double booking.
    Per instructions.txt lines 95-99: single transaction, UNIQUE constraints, fail fast.
    """
    # Check if flight exists
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Check if user has passenger profile
    user_profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == user_id
    ).first()
    if not user_profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please complete your passenger profile before booking"
        )
    
    # Lazy cleanup of expired holds
    cleanup_expired_holds(db, flight_id)
    
    # Validate all passenger profiles belong to user
    for passenger_data in passenger_data_list:
        passenger_profile_id = passenger_data.passenger_profile_id
        passenger_profile = db.query(PassengerProfile).filter(
            PassengerProfile.id == passenger_profile_id,
            PassengerProfile.user_id == user_id
        ).first()
        if not passenger_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Passenger profile {passenger_profile_id} not found or does not belong to user"
            )
    
    # Generate unique PNR
    pnr = generate_pnr()
    while db.query(Booking).filter(Booking.pnr == pnr).first():
        pnr = generate_pnr()
    
    # Create booking with 10-minute hold
    held_until = datetime.utcnow() + timedelta(minutes=10)
    booking = Booking(
        pnr=pnr,
        user_id=user_id,
        flight_id=flight_id,
        status=BookingStatus.CREATED,
        held_until=held_until
    )
    db.add(booking)
    db.flush()  # Get booking ID
    
    # Create seat holds and tickets in a single transaction
    # UNIQUE constraint on (flight_id, seat_number) will prevent double booking
    try:
        for passenger_data in passenger_data_list:
            seat_number = passenger_data.seat_number
            
            # Create seat hold - will fail if seat already held/booked
            seat_hold = SeatHold(
                flight_id=flight_id,
                seat_number=seat_number,
                booking_id=booking.id,
                held_until=held_until
            )
            db.add(seat_hold)
            db.flush()  # Will raise IntegrityError if seat already held
            
            # Create ticket
            ticket = Ticket(
                ticket_number=generate_ticket_number(),
                booking_id=booking.id,
                passenger_profile_id=passenger_data.passenger_profile_id,
                seat_number=seat_number,
                seat_category=passenger_data.seat_category or "STANDARD"
            )
            db.add(ticket)
        
        db.commit()
        db.refresh(booking)
        return booking
        
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more seats are already booked or held"
        )


def get_available_seats(db: Session, flight_id: int) -> list:
    """
    Get list of available seats for a flight.
    Excludes seats that are held or booked (not cancelled).
    """
    # Lazy cleanup
    cleanup_expired_holds(db, flight_id)
    
    # Get flight and airplane
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        return []
    
    # Get all held seats (including active holds)
    held_seats = set()
    for hold in db.query(SeatHold).filter(SeatHold.flight_id == flight_id).all():
        held_seats.add(hold.seat_number)
    
    # Also get seats from confirmed bookings (not in seat_hold table)
    for ticket in db.query(Ticket).join(Booking).filter(
        Booking.flight_id == flight_id,
        Booking.status == BookingStatus.CONFIRMED
    ).all():
        held_seats.add(ticket.seat_number)
    
    # Generate all possible seats from airplane template
    # This is simplified - in reality would parse seat_template
    all_seats = []
    seat_template = flight.airplane.seat_template
    rows = seat_template.get("rows", 30)
    seats_per_row = seat_template.get("seats_per_row", 6)
    
    # Generate seat numbers (simplified: A-F for 6 seats per row)
    seat_letters = "ABCDEFGHIJ"[:seats_per_row]
    for row in range(1, rows + 1):
        for letter in seat_letters:
            seat = f"{row}{letter}"
            if seat not in held_seats:
                all_seats.append(seat)
    
    return all_seats


def get_user_bookings(db: Session, user_id: int, upcoming_only: bool = False, past_only: bool = False):
    """Get user's bookings, filtered by upcoming/past or all"""
    from sqlalchemy.orm import joinedload
    
    query = db.query(Booking).filter(Booking.user_id == user_id).options(
        joinedload(Booking.tickets),
        joinedload(Booking.flight)
    )
    
    if upcoming_only:
        # Upcoming: departure is in the future
        query = query.join(Flight).filter(
            Flight.scheduled_departure > datetime.utcnow()
        )
    elif past_only:
        # Past: departure is in the past
        query = query.join(Flight).filter(
            Flight.scheduled_departure < datetime.utcnow()
        )
    # If neither flag is set, return all bookings (no date filter)
    
    return query.all()


def cancel_booking(db: Session, booking_id: int, user_id: int = None):
    """
    Cancel a booking and release seat holds.
    Only allowed before departure per instructions.txt line 166.
    """
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check authorization if user_id provided (passenger cancelling)
    if user_id and booking.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to cancel this booking"
        )
    
    # Check if flight has departed
    if booking.flight.scheduled_departure < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel booking after departure"
        )
    
    # Release seat holds
    db.query(SeatHold).filter(SeatHold.booking_id == booking_id).delete()
    
    # Cancel booking
    booking.status = BookingStatus.CANCELLED
    db.commit()
    db.refresh(booking)
    return booking


def list_bookings(db: Session, flight_id: int = None):
    """List all bookings, optionally filtered by flight"""
    query = db.query(Booking)
    if flight_id:
        query = query.filter(Booking.flight_id == flight_id)
    return query.all()


def reassign_seat(db: Session, booking_id: int, ticket_id: int, new_seat: str):
    """
    Reassign a seat for a ticket.
    Staff feature - can override per instructions.txt line 165.
    """
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    ticket = db.query(Ticket).filter(
        Ticket.id == ticket_id,
        Ticket.booking_id == booking_id
    ).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    old_seat = ticket.seat_number
    
    # Update seat hold if exists
    seat_hold = db.query(SeatHold).filter(
        SeatHold.booking_id == booking_id,
        SeatHold.seat_number == old_seat
    ).first()
    
    if seat_hold:
        # Try to update seat hold
        try:
            seat_hold.seat_number = new_seat
            db.flush()
        except IntegrityError:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Seat {new_seat} is already booked or held"
            )
    
    # Update ticket
    ticket.seat_number = new_seat
    db.commit()
    db.refresh(ticket)
    return ticket
