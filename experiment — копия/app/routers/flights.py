from typing import List, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload, selectinload
from datetime import date, datetime, timedelta

from app.routers import deps
from app.models import flight as flight_model
from app.models import aviation as aviation_model
from app.models import booking as booking_model
from app.models import user as user_model
from app.schemas import flight as flight_schema
from app.schemas import aviation as aviation_schema
from app.routers import announcements_helper

router = APIRouter()

# CRITICAL: Specific routes MUST be defined BEFORE parameterized routes
# FastAPI processes routes in order, so /all, /search must come before /{flight_id}
# Using /all instead of /available to avoid any potential conflicts

@router.get("/all", response_model=List[flight_schema.Flight])
def list_all_flights(
    db: Session = Depends(deps.get_db),
) -> Any:
    """Get all available flights (excluding cancelled and past flights)"""
    now = datetime.utcnow()
    flights = db.query(flight_model.Flight).filter(
        flight_model.Flight.status != flight_model.FlightStatus.CANCELLED,
        flight_model.Flight.departure_time >= now
    ).order_by(flight_model.Flight.departure_time).all()
    return flights

@router.get("/airports", response_model=List[aviation_schema.Airport])
def get_all_airports(
    db: Session = Depends(deps.get_db),
) -> Any:
    """Get all airports for search dropdowns"""
    return db.query(aviation_model.Airport).all()

@router.get("/search", response_model=List[flight_schema.Flight])
def search_flights(
    origin: str,
    destination: str,
    date_val: date = Query(..., alias="date"),
    db: Session = Depends(deps.get_db),
) -> Any:
    # Check and create time-based announcements (boarding notifications, etc.)
    announcements_helper.create_time_based_announcements(db)
    
    # Simple search: matching date part
    now = datetime.utcnow()
    flights = db.query(flight_model.Flight).filter(
        flight_model.Flight.departure_airport_code == origin,
        flight_model.Flight.arrival_airport_code == destination,
    ).all()
    
    result = []
    for f in flights:
        # Filter: same date, not cancelled, and departure time hasn't passed
        if (f.departure_time.date() == date_val 
            and f.status != flight_model.FlightStatus.CANCELLED
            and f.departure_time >= now):
            result.append(f)
            
    return result

@router.get("/{flight_id}", response_model=flight_schema.Flight)
def get_flight_details(
    flight_id: int,
    db: Session = Depends(deps.get_db),
) -> Any:
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    return flight

class SeatStatus(aviation_schema.Seat):
    is_occupied: bool
    is_held: bool = False
    
    class Config:
        from_attributes = True

@router.get("/{flight_id}/seats", response_model=List[SeatStatus])
def get_flight_seats(
    flight_id: int,
    db: Session = Depends(deps.get_db),
    current_user: Optional[user_model.User] = Depends(deps.get_current_active_user_optional),
) -> Any:
    try:
        # Auto-cancel expired pending bookings and clean up expired seat holds
        expire_time = datetime.utcnow() - timedelta(minutes=10)
        expired_bookings = db.query(booking_model.Booking).filter(
            booking_model.Booking.status == booking_model.BookingStatus.PENDING,
            booking_model.Booking.created_at < expire_time
        ).all()
        for expired_booking in expired_bookings:
            expired_booking.status = booking_model.BookingStatus.CANCELLED
        
        # Clean up expired seat holds
        db.query(booking_model.SeatHold).filter(
            booking_model.SeatHold.created_at < expire_time
        ).delete()
        
        if expired_bookings:
            db.commit()
        else:
            db.commit()
        
        # Eagerly load airplane and seats relationships
        flight = db.query(flight_model.Flight).options(
            joinedload(flight_model.Flight.airplane).selectinload(aviation_model.Airplane.seats)
        ).filter(flight_model.Flight.id == flight_id).first()
        
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
            
        airplane = flight.airplane
        if not airplane:
            raise HTTPException(status_code=400, detail="Flight has no airplane assigned")
        
        all_seats = airplane.seats
        if not all_seats:
            return []  # Return empty list if no seats configured
        
        # Get confirmed and pending bookings (excluding cancelled)
        expire_time = datetime.utcnow() - timedelta(minutes=10)
        
        confirmed_tickets = db.query(booking_model.Ticket).join(booking_model.Booking).filter(
            booking_model.Booking.flight_id == flight_id,
            booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
        ).all()
        
        pending_tickets = db.query(booking_model.Ticket).join(booking_model.Booking).filter(
            booking_model.Booking.flight_id == flight_id,
            booking_model.Booking.status == booking_model.BookingStatus.PENDING,
            booking_model.Booking.created_at > expire_time
        ).all()
        
        # Get active seat holds (not expired)
        active_holds = db.query(booking_model.SeatHold).filter(
            booking_model.SeatHold.flight_id == flight_id,
            booking_model.SeatHold.created_at > expire_time
        ).all()
        
        occupied_seat_nums = {t.seat_number for t in confirmed_tickets}
        held_seat_nums = {t.seat_number for t in pending_tickets}
        held_seat_nums.update({h.seat_number for h in active_holds})  # Include seat holds
        
        result = []
        for s in all_seats:
            # Create base seat data
            seat_dict = {
                "id": s.id,
                "airplane_id": s.airplane_id,
                "seat_number": s.seat_number,
                "category": s.category,
                "is_occupied": s.seat_number in occupied_seat_nums,
                "is_held": s.seat_number in held_seat_nums and s.seat_number not in occupied_seat_nums
            }
            result.append(SeatStatus(**seat_dict))
            
        return result
    except HTTPException:
        raise
    except Exception as e:
        # Log the error for debugging
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{flight_id}/announcements", response_model=List[flight_schema.Announcement])
def get_flight_announcements(
    flight_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    flight = db.query(flight_model.Flight).filter(flight_model.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    # Get public announcements (user_id is NULL) and personal announcements for current user
    # Public announcements are shown to all users who have bookings for this flight
    from sqlalchemy import or_
    announcements = db.query(flight_model.Announcement).filter(
        flight_model.Announcement.flight_id == flight_id,
        or_(
            flight_model.Announcement.user_id == None,  # Public announcements
            flight_model.Announcement.user_id == current_user.id  # Personal announcements
        )
    ).order_by(flight_model.Announcement.created_at.desc()).all()
    
    return announcements
