from typing import List, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime, timedelta
import uuid
import random
import string

from app.routers import deps
from app.models import user as user_model
from app.models import flight as flight_model
from app.models import booking as booking_model
from app.models import aviation as aviation_model
from app.schemas import booking as booking_schema

router = APIRouter()

def generate_pnr() -> str:
    """Generate a 6-character alphanumeric PNR"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=6))

def generate_ticket_number() -> str:
    """Generate a unique ticket number"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=13))

def cancel_expired_pending_bookings(db: Session) -> None:
    """
    Automatically cancel all PENDING bookings that are older than 10 minutes.
    This makes seats available again for other users.
    """
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_bookings = db.query(booking_model.Booking).filter(
        booking_model.Booking.status == booking_model.BookingStatus.PENDING,
        booking_model.Booking.created_at < expire_time
    ).all()
    
    for expired_booking in expired_bookings:
        expired_booking.status = booking_model.BookingStatus.CANCELLED
    
    # Also clean up expired seat holds
    deleted_holds = db.query(booking_model.SeatHold).filter(
        booking_model.SeatHold.created_at < expire_time
    ).delete()
    
    # Commit if there were any changes
    if expired_bookings or deleted_holds:
        db.commit()

@router.post("/", response_model=booking_schema.Booking)
def create_booking(
    *,
    db: Session = Depends(deps.get_db),
    booking_in: booking_schema.BookingCreate,
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    # 1. Check Profile
    if not current_user.profile or not all([
        current_user.profile.phone_number,
        current_user.profile.passport_number,
        current_user.profile.nationality,
        current_user.profile.birth_date
    ]):
        raise HTTPException(status_code=400, detail="Profile must be fully filled before booking.")

    # 2. Check Flight
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == booking_in.flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    if flight.status == flight_model.FlightStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Cannot book cancelled flights")
    if flight.departure_time < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Cannot book past flights")

    # 2.5. Auto-cancel expired pending bookings and clean up expired seat holds (cleanup before checking seats)
    cancel_expired_pending_bookings(db)

    # 3. Check Seats availability and handle auto-assignment
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    
    # Get all airplane seats
    airplane_seat_numbers = {s.seat_number for s in flight.airplane.seats}
    
    # Separate passengers with and without seat selection
    passengers_with_seats = [p for p in booking_in.passengers if p.seat_number]
    passengers_without_seats = [p for p in booking_in.passengers if not p.seat_number]
    
    # Check requested seats for duplicates
    requested_seats = [p.seat_number for p in passengers_with_seats]
    if len(requested_seats) != len(set(requested_seats)):
        raise HTTPException(status_code=400, detail="Duplicate seats in request")
    
    # Verify requested seats exist on airplane
    invalid_seats = [seat for seat in requested_seats if seat not in airplane_seat_numbers]
    if invalid_seats:
        raise HTTPException(status_code=400, detail=f"Invalid seat numbers: {invalid_seats}")

    # Find blocking tickets and seat holds for requested seats
    if requested_seats:
        blocking_tickets = db.query(booking_model.Ticket).join(booking_model.Booking).filter(
            booking_model.Booking.flight_id == flight.id,
            booking_model.Ticket.seat_number.in_(requested_seats),
            booking_model.Booking.status != booking_model.BookingStatus.CANCELLED,
            or_(
                booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED,
                and_(
                    booking_model.Booking.status == booking_model.BookingStatus.PENDING,
                    booking_model.Booking.created_at > expire_time
                )
            )
        ).all()
        
        # Also check seat holds (excluding current user's holds which will be released)
        blocking_holds = db.query(booking_model.SeatHold).filter(
            booking_model.SeatHold.flight_id == flight.id,
            booking_model.SeatHold.created_at > expire_time,
            booking_model.SeatHold.seat_number.in_(requested_seats),
            booking_model.SeatHold.user_id != current_user.id  # Allow own holds
        ).all()
        
        if blocking_tickets:
            raise HTTPException(status_code=409, detail=f"One or more seats are already taken: {[t.seat_number for t in blocking_tickets]}")
        if blocking_holds:
            raise HTTPException(status_code=409, detail=f"One or more seats are temporarily held: {[h.seat_number for h in blocking_holds]}")
    
    # Get all occupied/held seats for auto-assignment
    all_blocking_tickets = db.query(booking_model.Ticket).join(booking_model.Booking).filter(
        booking_model.Booking.flight_id == flight.id,
        booking_model.Booking.status != booking_model.BookingStatus.CANCELLED,
        or_(
            booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED,
            and_(
                booking_model.Booking.status == booking_model.BookingStatus.PENDING,
                booking_model.Booking.created_at > expire_time
            )
        )
    ).all()
    
    occupied_seats = {t.seat_number for t in all_blocking_tickets}
    occupied_seats.update(requested_seats)  # Include requested seats
    
    # Find available seats for auto-assignment
    available_seats = sorted(list(airplane_seat_numbers - occupied_seats))
    
    # Check if we have enough seats for auto-assignment
    if len(passengers_without_seats) > len(available_seats):
        raise HTTPException(
            status_code=409, 
            detail=f"Not enough available seats. Requested {len(passengers_without_seats)} seats, but only {len(available_seats)} available."
        )
    
    # Assign seats to passengers without seat selection (create new objects with assigned seats)
    passengers_with_assigned_seats = []
    for i, passenger in enumerate(passengers_without_seats):
        # Create a new TicketCreate object with assigned seat using model_copy
        passenger_with_seat = passenger.model_copy(update={"seat_number": available_seats[i]})
        passengers_with_assigned_seats.append(passenger_with_seat)
    
    # Combine all passengers (with selected seats and auto-assigned seats)
    all_passengers = passengers_with_seats + passengers_with_assigned_seats

    # 4. Create Booking
    # Generate unique PNR
    while True:
        pnr = generate_pnr()
        existing = db.query(booking_model.Booking).filter(booking_model.Booking.pnr == pnr).first()
        if not existing:
            break
    
    total_price = flight.base_price * len(booking_in.passengers)
    
    booking = booking_model.Booking(
        pnr=pnr,
        user_id=current_user.id,
        flight_id=flight.id,
        status=booking_model.BookingStatus.PENDING,
        created_at=datetime.utcnow(),
        total_price=total_price
    )
    db.add(booking)
    db.flush() # get ID

    # 5. Create Tickets
    tickets = []
    for p in all_passengers:
        # Generate unique ticket number
        while True:
            ticket_number = generate_ticket_number()
            existing = db.query(booking_model.Ticket).filter(booking_model.Ticket.ticket_number == ticket_number).first()
            if not existing:
                break
        
        # seat_number should be assigned by now (either from request or auto-assignment)
        ticket = booking_model.Ticket(
            booking_id=booking.id,
            passenger_name=p.passenger_name,
            passport_number=p.passport_number,
            seat_number=p.seat_number,
            ticket_number=ticket_number
        )
        tickets.append(ticket)
    
    db.add_all(tickets)
    
    # Release seat holds for this user's seats (convert to booking)
    requested_seat_numbers = [p.seat_number for p in all_passengers if p.seat_number]
    if requested_seat_numbers:
        db.query(booking_model.SeatHold).filter(
            booking_model.SeatHold.flight_id == flight.id,
            booking_model.SeatHold.user_id == current_user.id,
            booking_model.SeatHold.seat_number.in_(requested_seat_numbers)
        ).delete()
    
        # Create personal announcement when booking is created (only for this user)
    announcement = flight_model.Announcement(
        flight_id=flight.id,
        user_id=current_user.id,  # Personal announcement for this user only
        title="Booking Created",
        message=f"Your booking for flight {flight.flight_number} has been created. PNR: {booking.pnr}. Please pay within 10 minutes to confirm your booking.",
        type=flight_model.AnnouncementType.GENERAL_INFO,
        created_at=datetime.utcnow()
    )
    db.add(announcement)
    
    # Create notification for booking created
    notification = flight_model.UserNotification(
        user_id=current_user.id,
        type=flight_model.UserNotificationType.BOOKING_CONFIRMED,
        message=f"Your booking for flight {flight.flight_number} has been created. PNR: {booking.pnr}. Please pay within 10 minutes to confirm your booking.",
        created_at=datetime.utcnow(),
        is_read=False
    )
    db.add(notification)
    
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/{booking_id}/pay", response_model=booking_schema.Booking)
def pay_booking(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    try:
        # Auto-cancel expired pending bookings before processing payment
        cancel_expired_pending_bookings(db)
        
        booking = db.query(booking_model.Booking).filter(
            booking_model.Booking.id == booking_id,
            booking_model.Booking.user_id == current_user.id
        ).first()
        
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        
        # Check if booking was cancelled due to expiration
        if booking.status == booking_model.BookingStatus.CANCELLED:
            expire_time = datetime.utcnow() - timedelta(minutes=10)
            if booking.created_at < expire_time:
                raise HTTPException(status_code=400, detail="Booking expired and was cancelled. Please create a new booking.")
            else:
                raise HTTPException(status_code=400, detail="Booking has been cancelled")
            
        if booking.status != booking_model.BookingStatus.PENDING:
            raise HTTPException(
                status_code=400, 
                detail=f"Booking is not pending. Current status: {booking.status.value}"
            )
            
        # Double-check expiration
        expire_time = datetime.utcnow() - timedelta(minutes=10)
        if booking.created_at < expire_time:
            booking.status = booking_model.BookingStatus.CANCELLED
            db.commit()
            raise HTTPException(status_code=400, detail="Booking expired. Please create a new booking.")

        # Mock Payment
        payment = booking_model.Payment(
            booking_id=booking.id,
            amount=booking.total_price,
            method=booking_model.PaymentMethod.CARD,
            status=booking_model.PaymentStatus.PAID,
            created_at=datetime.utcnow()
        )
        booking.status = booking_model.BookingStatus.CONFIRMED
        booking.payment = payment
        
        # Create announcement when payment is confirmed
        flight = booking.flight
        
        # Personal announcement about booking confirmation (only for this user)
        confirmation_announcement = flight_model.Announcement(
            flight_id=flight.id,
            user_id=current_user.id,  # Personal announcement for this user only
            title="Booking Confirmed",
            message=f"Your booking for flight {flight.flight_number} has been confirmed. PNR: {booking.pnr}. Check-in will be available 24 hours before departure.",
            type=flight_model.AnnouncementType.GENERAL_INFO,
            created_at=datetime.utcnow()
        )
        db.add(confirmation_announcement)
        
        # Create notification for booking confirmed
        booking_notification = flight_model.UserNotification(
            user_id=current_user.id,
            type=flight_model.UserNotificationType.BOOKING_CONFIRMED,
            message=f"Your booking for flight {flight.flight_number} has been confirmed. PNR: {booking.pnr}. Check-in will be available 24 hours before departure.",
            created_at=datetime.utcnow(),
            is_read=False
        )
        db.add(booking_notification)
        
        # Create notification for ticket purchased
        ticket_notification = flight_model.UserNotification(
            user_id=current_user.id,
            type=flight_model.UserNotificationType.TICKET_PURCHASED,
            message=f"Your tickets for flight {flight.flight_number} have been purchased. PNR: {booking.pnr}. You can check-in 24 hours before departure.",
            created_at=datetime.utcnow(),
            is_read=False
        )
        db.add(ticket_notification)
        
        db.add(payment)
        db.commit()
        db.refresh(booking)
        return booking
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/me", response_model=List[booking_schema.Booking])
def get_my_bookings(
    future: bool = Query(False, description="Show only future bookings"),
    past: bool = Query(False, description="Show only past bookings"),
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    # Check and create time-based announcements (boarding notifications, etc.)
    from app.routers import announcements_helper
    announcements_helper.create_time_based_announcements(db)
    
    # Auto-cancel expired pending bookings before fetching user's bookings
    cancel_expired_pending_bookings(db)
    
    bookings_query = db.query(booking_model.Booking).filter(booking_model.Booking.user_id == current_user.id)
    
    now = datetime.utcnow()
    if future:
        bookings_query = bookings_query.join(flight_model.Flight).filter(flight_model.Flight.departure_time > now)
    elif past:
        bookings_query = bookings_query.join(flight_model.Flight).filter(flight_model.Flight.departure_time < now)
    
    return bookings_query.all()

@router.get("/by-pnr/{pnr}", response_model=booking_schema.Booking)
def get_booking_by_pnr(
    pnr: str,
    last_name: str = Query(..., description="Last name of the passenger for verification"),
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Public endpoint to retrieve booking by PNR code and last name.
    This allows passengers to manage their bookings without logging in, similar to Turkish Airlines.
    """
    # Auto-cancel expired pending bookings before fetching booking
    cancel_expired_pending_bookings(db)
    
    booking = db.query(booking_model.Booking).filter(
        booking_model.Booking.pnr == pnr.upper()
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check if this specific booking has expired (additional check)
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    if booking.status == booking_model.BookingStatus.PENDING and booking.created_at < expire_time:
        booking.status = booking_model.BookingStatus.CANCELLED
        db.commit()
        db.refresh(booking)
    
    # Verify last name matches any passenger in the booking
    last_name_lower = last_name.lower().strip()
    passenger_names = [ticket.passenger_name.lower() for ticket in booking.tickets]
    
    # Check if any passenger's last name matches
    last_name_match = False
    for passenger_name in passenger_names:
        # Split name and check last name (assumes format: "First Last" or "First Middle Last")
        name_parts = passenger_name.split()
        if name_parts and name_parts[-1] == last_name_lower:
            last_name_match = True
            break
    
    if not last_name_match:
        raise HTTPException(
            status_code=403, 
            detail="Last name does not match any passenger in this booking"
        )
    
    return booking

@router.get("/{booking_id}", response_model=booking_schema.Booking)
def get_booking_details(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    # Auto-cancel expired pending bookings before fetching booking details
    cancel_expired_pending_bookings(db)
    
    booking = db.query(booking_model.Booking).filter(
        booking_model.Booking.id == booking_id,
        booking_model.Booking.user_id == current_user.id
    ).first()
    if not booking:
         raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check if this specific booking has expired (additional check)
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    if booking.status == booking_model.BookingStatus.PENDING and booking.created_at < expire_time:
        booking.status = booking_model.BookingStatus.CANCELLED
        db.commit()
        db.refresh(booking)
    
    return booking
