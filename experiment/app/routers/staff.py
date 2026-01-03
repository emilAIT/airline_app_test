from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime, timedelta
from pydantic import BaseModel

from app.routers import deps
from app.models import user as user_model
from app.models import aviation as aviation_model
from app.models import flight as flight_model
from app.models import booking as booking_model
from app.schemas import aviation as aviation_schema
from app.schemas import flight as flight_schema
from app.schemas import booking as booking_schema

router = APIRouter()

# Dependency to check for staff
def get_current_staff_user(
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> user_model.User:
    if current_user.role != user_model.UserRole.STAFF:
        raise HTTPException(status_code=400, detail="Not enough privileges")
    return current_user

# --- Airports ---
@router.get("/airports", response_model=List[aviation_schema.Airport])
def list_airports(
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airports = db.query(aviation_model.Airport).all()
    return airports

@router.post("/airports", response_model=aviation_schema.Airport)
def create_airport(
    *,
    db: Session = Depends(deps.get_db),
    airport_in: aviation_schema.AirportCreate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airport = aviation_model.Airport(**airport_in.model_dump())
    db.add(airport)
    db.commit()
    db.refresh(airport)
    return airport

@router.put("/airports/{code}", response_model=aviation_schema.Airport)
def update_airport(
    *,
    db: Session = Depends(deps.get_db),
    code: str,
    airport_update: aviation_schema.AirportUpdate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airport = db.query(aviation_model.Airport).filter(aviation_model.Airport.code == code).first()
    if not airport:
        raise HTTPException(status_code=404, detail="Airport not found")
    
    for field, value in airport_update.model_dump(exclude_unset=True).items():
        setattr(airport, field, value)
    
    db.commit()
    db.refresh(airport)
    return airport

@router.delete("/airports/{code}", response_model=aviation_schema.Airport)
def delete_airport(
    *,
    db: Session = Depends(deps.get_db),
    code: str,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airport = db.query(aviation_model.Airport).filter(aviation_model.Airport.code == code).first()
    if not airport:
        raise HTTPException(status_code=404, detail="Airport not found")
    
    # Check for dependent flights
    dep_flights = db.query(flight_model.Flight).filter(flight_model.Flight.departure_airport_code == code).first()
    arr_flights = db.query(flight_model.Flight).filter(flight_model.Flight.arrival_airport_code == code).first()
    
    if dep_flights or arr_flights:
         raise HTTPException(status_code=400, detail="Cannot delete airport with existing flights.")

    db.delete(airport)
    db.commit()
    return airport

# --- Airplanes ---
@router.get("/airplanes", response_model=List[aviation_schema.Airplane])
def list_airplanes(
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airplanes = db.query(aviation_model.Airplane).all()
    return airplanes

@router.post("/airplanes", response_model=aviation_schema.Airplane)
def create_airplane(
    *,
    db: Session = Depends(deps.get_db),
    airplane_in: aviation_schema.AirplaneCreate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    # Create airplane
    airplane = aviation_model.Airplane(
        name=airplane_in.name,
        model=airplane_in.model
    )
    db.add(airplane)
    db.commit()
    db.refresh(airplane)

    # Generate seats
    seats = []
    rows = airplane_in.rows
    cols = airplane_in.seats_per_row
    letters = "ABCDEFGHJK" # Skip I
    
    for r in range(1, rows + 1):
        for c in range(cols):
            seat_letter = letters[c]
            seat_num = f"{r}{seat_letter}"
            category = "Business" if r <= airplane_in.business_rows else "Economy"
            seat = aviation_model.Seat(
                airplane_id=airplane.id,
                seat_number=seat_num,
                category=category
            )
            seats.append(seat)
    
    db.add_all(seats)
    db.commit()
    db.refresh(airplane)
    return airplane

@router.put("/airplanes/{airplane_id}", response_model=aviation_schema.Airplane)
def update_airplane(
    *,
    db: Session = Depends(deps.get_db),
    airplane_id: int,
    airplane_update: aviation_schema.AirplaneUpdate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airplane = db.query(aviation_model.Airplane).filter(aviation_model.Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=404, detail="Airplane not found")
    
    for field, value in airplane_update.model_dump(exclude_unset=True).items():
        setattr(airplane, field, value)
    
    db.commit()
    db.refresh(airplane)
    return airplane

@router.get("/airplanes/{airplane_id}/seats", response_model=List[aviation_schema.Seat])
def read_seats(
    airplane_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airplane = db.query(aviation_model.Airplane).filter(aviation_model.Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=404, detail="Airplane not found")
    return airplane.seats

@router.delete("/airplanes/{airplane_id}", response_model=aviation_schema.Airplane)
def delete_airplane(
    *,
    db: Session = Depends(deps.get_db),
    airplane_id: int,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    airplane = db.query(aviation_model.Airplane).filter(aviation_model.Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=404, detail="Airplane not found")
    
    # Check dependencies
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.airplane_id == airplane_id).first()
    if flight:
        raise HTTPException(status_code=400, detail="Cannot delete airplane assigned to flights.")

    db.delete(airplane)
    db.commit()
    return airplane

# --- Flights ---
@router.get("/flights", response_model=List[flight_schema.Flight])
def list_flights(
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    flights = db.query(flight_model.Flight).all()
    return flights

@router.get("/flights/{flight_id}", response_model=flight_schema.Flight)
def get_flight(
    flight_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    return flight

@router.post("/flights", response_model=flight_schema.Flight)
def create_flight(
    *,
    db: Session = Depends(deps.get_db),
    flight_in: flight_schema.FlightCreate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    flight = flight_model.Flight(**flight_in.model_dump())
    db.add(flight)
    db.commit()
    db.refresh(flight)
    return flight

@router.put("/flights/{flight_id}", response_model=flight_schema.Flight)
def update_flight(
    *,
    db: Session = Depends(deps.get_db),
    flight_id: int,
    flight_update: flight_schema.FlightUpdate,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    # Track if status changed
    old_status = flight.status
    status_changed = False
    
    for field, value in flight_update.model_dump(exclude_unset=True).items():
        if field == 'status' and value != old_status:
            status_changed = True
        setattr(flight, field, value)
    
    # If status changed, create notifications for all users with bookings on this flight
    if status_changed and flight_update.status:
        # Get all confirmed bookings for this flight
        bookings = db.query(booking_model.Booking).filter(
            booking_model.Booking.flight_id == flight_id,
            booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
        ).all()
        
        # Create notifications for each user
        for booking in bookings:
            status_message = f"Flight {flight.flight_number} status has been updated to {flight_update.status.value}."
            if flight_update.status == flight_model.FlightStatus.DELAYED:
                status_message = f"Flight {flight.flight_number} has been delayed. Please check for updated departure time."
            elif flight_update.status == flight_model.FlightStatus.CANCELLED:
                status_message = f"Flight {flight.flight_number} has been cancelled. Please contact customer service for assistance."
            elif flight_update.status == flight_model.FlightStatus.BOARDING:
                status_message = f"Boarding has started for flight {flight.flight_number}. Please proceed to gate {flight.gate or 'TBD'}."
            
            notification = flight_model.UserNotification(
                user_id=booking.user_id,
                type=flight_model.UserNotificationType.FLIGHT_UPDATE,
                message=status_message,
                created_at=datetime.utcnow(),
                is_read=False
            )
            db.add(notification)
    
    db.commit()
    db.refresh(flight)
    return flight

@router.delete("/flights/{flight_id}", response_model=flight_schema.Flight)
def delete_flight(
    *,
    db: Session = Depends(deps.get_db),
    flight_id: int,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    # Check bookings
    booking = db.query(booking_model.Booking).filter(
        booking_model.Booking.flight_id == flight_id, 
        booking_model.Booking.status != booking_model.BookingStatus.CANCELLED
    ).first()
    
    if booking:
         raise HTTPException(status_code=400, detail="Cannot delete flight with active bookings. Cancel them first.")

    # Delete all announcements associated with this flight first
    # This prevents NOT NULL constraint error when deleting the flight
    db.query(flight_model.Announcement).filter(
        flight_model.Announcement.flight_id == flight_id
    ).delete()
    
    # Delete the flight
    db.delete(flight)
    db.commit()
    return flight

@router.post("/flights/{flight_id}/announcements", response_model=flight_schema.Announcement)
def create_announcement(
    *,
    db: Session = Depends(deps.get_db),
    flight_id: int,
    announcement_in: flight_schema.AnnouncementBase,
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    # Create public announcement (user_id = None means it's for all users on this flight)
    announcement = flight_model.Announcement(
        **announcement_in.model_dump(),
        flight_id=flight_id,
        user_id=None,  # Explicitly set to None for public announcement
        created_at=datetime.utcnow()
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement

# --- Bookings ---
class SeatReassignment(BaseModel):
    ticket_id: int
    new_seat_number: str

@router.get("/bookings", response_model=List[booking_schema.Booking])
def list_all_bookings(
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    """Get all bookings for staff management"""
    # Auto-cancel expired pending bookings before fetching
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_bookings = db.query(booking_model.Booking).filter(
        booking_model.Booking.status == booking_model.BookingStatus.PENDING,
        booking_model.Booking.created_at < expire_time
    ).all()
    for expired_booking in expired_bookings:
        expired_booking.status = booking_model.BookingStatus.CANCELLED
    if expired_bookings:
        db.commit()
    
    bookings = db.query(booking_model.Booking).order_by(booking_model.Booking.created_at.desc()).all()
    return bookings

@router.get("/bookings/by-pnr/{pnr}", response_model=booking_schema.Booking)
def get_booking_by_pnr(
    pnr: str,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    # Auto-cancel expired pending bookings before fetching
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_bookings = db.query(booking_model.Booking).filter(
        booking_model.Booking.status == booking_model.BookingStatus.PENDING,
        booking_model.Booking.created_at < expire_time
    ).all()
    for expired_booking in expired_bookings:
        expired_booking.status = booking_model.BookingStatus.CANCELLED
    if expired_bookings:
        db.commit()
    
    booking = db.query(booking_model.Booking).filter(booking_model.Booking.pnr == pnr).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check if this specific booking has expired
    if booking.status == booking_model.BookingStatus.PENDING and booking.created_at < expire_time:
        booking.status = booking_model.BookingStatus.CANCELLED
        db.commit()
        db.refresh(booking)
    
    return booking

@router.get("/bookings/by-flight/{flight_id}", response_model=List[booking_schema.Booking])
def get_bookings_by_flight(
    flight_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    # Auto-cancel expired pending bookings before fetching
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_bookings = db.query(booking_model.Booking).filter(
        booking_model.Booking.status == booking_model.BookingStatus.PENDING,
        booking_model.Booking.created_at < expire_time
    ).all()
    for expired_booking in expired_bookings:
        expired_booking.status = booking_model.BookingStatus.CANCELLED
    if expired_bookings:
        db.commit()
    
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    bookings = db.query(booking_model.Booking).filter(
        booking_model.Booking.flight_id == flight_id
    ).all()
    return bookings

@router.post("/bookings/{booking_id}/cancel", response_model=booking_schema.Booking)
def cancel_booking(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    booking = db.query(booking_model.Booking).filter(booking_model.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    flight = booking.flight
    if flight.departure_time < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Cannot cancel booking for departed flights")
    
    booking.status = booking_model.BookingStatus.CANCELLED
    db.commit()
    db.refresh(booking)
    return booking

@router.delete("/bookings/{booking_id}")
def delete_booking(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    """Delete a booking permanently (admin only)"""
    booking = db.query(booking_model.Booking).filter(booking_model.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Load relationships before deletion to avoid DetachedInstanceError
    booking_id_copy = booking.id
    pnr_copy = booking.pnr
    
    # Delete associated tickets first (cascade should handle this, but explicit is better)
    db.query(booking_model.Ticket).filter(booking_model.Ticket.booking_id == booking_id).delete()
    
    # Delete payment if exists
    if booking.payment:
        db.delete(booking.payment)
    
    # Delete the booking
    db.delete(booking)
    db.commit()
    
    # Return a simple success message instead of the deleted object
    return {"message": "Booking deleted successfully", "pnr": pnr_copy, "id": booking_id_copy}

@router.post("/bookings/reassign-seat", response_model=booking_schema.Booking)
def reassign_seat(
    reassignment: SeatReassignment,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(get_current_staff_user),
) -> Any:
    ticket = db.query(booking_model.Ticket).filter(booking_model.Ticket.id == reassignment.ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    booking = ticket.booking
    flight = booking.flight
    old_seat = ticket.seat_number
    
    # Check if new seat exists on airplane
    airplane_seat_numbers = {s.seat_number for s in flight.airplane.seats}
    if reassignment.new_seat_number not in airplane_seat_numbers:
        raise HTTPException(status_code=400, detail="Invalid seat number")
    
    # Check if new seat is available
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    blocking_tickets = db.query(booking_model.Ticket).join(booking_model.Booking).filter(
        booking_model.Booking.flight_id == flight.id,
        booking_model.Ticket.seat_number == reassignment.new_seat_number,
        booking_model.Ticket.id != ticket.id,  # Exclude current ticket
        booking_model.Booking.status != booking_model.BookingStatus.CANCELLED,
        or_(
            booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED,
            and_(
                booking_model.Booking.status == booking_model.BookingStatus.PENDING,
                booking_model.Booking.created_at > expire_time
            )
        )
    ).first()
    
    if blocking_tickets:
        raise HTTPException(status_code=409, detail="Seat is already taken")
    
    # Update seat
    ticket.seat_number = reassignment.new_seat_number
    
    # Create personal announcement to notify passenger about seat change (only for booking owner)
    announcement = flight_model.Announcement(
        flight_id=flight.id,
        user_id=booking.user_id,  # Personal announcement for booking owner
        title=f"Seat Change - {ticket.passenger_name}",
        message=f"Your seat has been changed from {old_seat} to {reassignment.new_seat_number} for flight {flight.flight_number}. Please check your booking details.",
        type=flight_model.AnnouncementType.GENERAL_INFO,
        created_at=datetime.utcnow()
    )
    db.add(announcement)
    
    db.commit()
    db.refresh(booking)
    return booking

