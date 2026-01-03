from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import random
import string
from app.models.booking import Booking, Ticket, BookingStatus
from app.models.passenger import PassengerProfile
from app.models.flight import Flight, FlightStatus
from app.schemas.booking import BookingCreate, PassengerInfo
from app.services.seat_hold import get_available_seats, hold_seats, release_holds_for_booking
from fastapi import HTTPException, status


def generate_pnr() -> str:
    """Generate unique 6-character PNR code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


def generate_ticket_number() -> str:
    """Generate unique ticket number"""
    return f"TK{''.join(random.choices(string.ascii_uppercase + string.digits, k=10))}"


def create_booking(
    db: Session,
    user_id: int,
    booking_data: BookingCreate
) -> Booking:
    """Create a new booking with tickets"""
    # Validate flight
    flight = db.query(Flight).filter(Flight.id == booking_data.flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Check flight status
    # Block if departed, landed, boarding or cancelled
    if flight.status in [FlightStatus.CANCELLED, FlightStatus.DEPARTED, FlightStatus.LANDED, FlightStatus.BOARDING]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot book flight in {flight.status.value} status"
        )
        
    # Extra safety: block if less than 60 minutes to departure
    # Extra safety: block if less than 60 minutes to departure
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    if now > flight.departure_time - timedelta(minutes=60):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Booking is closed for this flight (less than 1 hour to departure)"
        )
    
    # Validate passengers
    passenger_ids = [p.passenger_profile_id for p in booking_data.passengers]
    passengers = db.query(PassengerProfile).filter(
        PassengerProfile.id.in_(passenger_ids)
    ).all()
    
    if len(passengers) != len(passenger_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more passenger profiles not found"
        )
    
    # Get available seats
    available_seats_resp = get_available_seats(db, booking_data.flight_id, include_held=False)
    available_seats = available_seats_resp["seat_map"]
    
    # Validate and assign seats
    seats_to_hold = []
    for passenger_info in booking_data.passengers:
        if passenger_info.seat_number:
            # Validate seat
            if passenger_info.seat_number not in available_seats:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Seat {passenger_info.seat_number} does not exist"
                )
            
            if not available_seats[passenger_info.seat_number]["available"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Seat {passenger_info.seat_number} is not available"
                )
            
            seats_to_hold.append(passenger_info.seat_number)
    
    # Create booking
    pnr = generate_pnr()
    # Ensure PNR is unique
    while db.query(Booking).filter(Booking.pnr == pnr).first():
        pnr = generate_pnr()
    
    booking = Booking(
        pnr=pnr,
        user_id=user_id,
        flight_id=booking_data.flight_id,
        status=BookingStatus.HOLD,
        created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
    )
    db.add(booking)
    db.flush()  # Get booking.id
    
    # Hold seats if specified
    if seats_to_hold:
        try:
           # Hold seats for 10 minutes for the booking
            hold_seats(db, flight.id, seats_to_hold, booking.id, hold_duration_minutes=10)
        except ValueError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e)
            )
    
    # Create tickets
    seat_index = 0
    for passenger_info in booking_data.passengers:
        ticket_number = generate_ticket_number()
        # Ensure ticket number is unique
        while db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first():
            ticket_number = generate_ticket_number()
        
        # Assign seat if not specified
        seat_number = passenger_info.seat_number
        if not seat_number:
            # Auto-assign from available seats
            available_seat_list = [
                seat for seat, info in available_seats.items()
                if info["available"] and seat not in seats_to_hold
            ]
            if available_seat_list:
                seat_number = available_seat_list[seat_index % len(available_seat_list)]
                seat_index += 1
                seats_to_hold.append(seat_number)
                try:
                    hold_seats(db, booking_data.flight_id, [seat_number], booking.id)
                except ValueError:
                    pass  # Continue if seat becomes unavailable
        
        # Calculate price for this seat
        ticket_price = flight.price
        if seat_number and seat_number in available_seats:
            ticket_price = available_seats[seat_number]["price"]

        ticket = Ticket(
            ticket_number=ticket_number,
            booking_id=booking.id,
            passenger_profile_id=passenger_info.passenger_profile_id,
            seat_number=seat_number,
            price=ticket_price
        )
        db.add(ticket)
    
    db.commit()
    db.refresh(booking)
    return booking


def cancel_expired_bookings(db: Session):
    """
    Cancel bookings that are pending payment (CREATED) and older than 5 minutes.
    This frees up seats for other users.
    """
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    # Targeted: Bookings in 'HOLD' status created more than 10 minutes ago
    expire_threshold = now - timedelta(minutes=10)
    
    # metrics for logging
    deleted_count = 0
    
    expired_bookings = db.query(Booking).filter(
        Booking.status == BookingStatus.HOLD,
        Booking.created_at < expire_threshold
    ).all()
    
    from app.models.notification import Notification, NotificationType
    for booking in expired_bookings:
        # Release seat holds first
        release_holds_for_booking(db, booking.id)
        
        # Mark as EXPIRED instead of deleting
        booking.status = BookingStatus.EXPIRED
        
        # Create notification for the user
        notification = Notification(
            user_id=booking.user_id,
            type=NotificationType.BOOKING_EXPIRED,
            title="Booking Expired",
            message=f"Your booking (PNR: {booking.pnr}) has expired due to non-payment. The held seats have been released.",
            created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
        )
        db.add(notification)
        deleted_count += 1
        
    if deleted_count > 0:
        db.commit()
        print(f"Cleanup: Expired {deleted_count} bookings and sent notifications")
    
    # Also release any orphaned seat holds that expired
    from app.services.seat_hold import release_expired_holds
    release_expired_holds(db)
