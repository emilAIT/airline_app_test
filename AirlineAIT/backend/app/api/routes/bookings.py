"""
Bookings API routes.

Endpoints:
- POST /: Create new booking (requires profile)
- GET /: Get user's bookings
- GET /{booking_id}: Get booking details
- GET /pnr/{pnr}: Lookup booking by PNR
- PUT /{booking_id}/cancel: Cancel booking

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from app.db.session import get_db
from app.api.deps import get_current_passenger
from app.models.user import User
from app.models.booking import Booking, BookingStatus
from app.models.flight import Flight
from app.schemas.booking import BookingCreate, BookingResponse, BookingDetailResponse
from app.services.booking import create_booking
from app.api.routes.staff import update_flight_status_based_on_time

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def create_booking_endpoint(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Create a new booking"""
    # Check if user has profile
    from app.models.passenger import PassengerProfile
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Profile must be completed before booking a flight"
        )
    
    booking = create_booking(db, current_user.id, booking_data)
    
    # Return with server time and expiration
    # Return with server time and expiration
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    res = BookingResponse.model_validate(booking).model_dump()
    res['server_time'] = now
    res['expires_at'] = booking.created_at + timedelta(minutes=10)
    return res


@router.get("", response_model=List[BookingResponse])
def get_my_bookings(
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get all bookings for current user"""
    from app.services.booking import cancel_expired_bookings
    cancel_expired_bookings(db)
    
    bookings = db.query(Booking).filter(
        Booking.user_id == current_user.id
    ).order_by(Booking.created_at.desc()).all()

    # Trigger auto-status updates for flights in these bookings
    updates = False
    for b in bookings:
        if b.flight and update_flight_status_based_on_time(b.flight, db):
            updates = True
    if updates:
        db.commit()
    
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    results = []
    for b in bookings:
        res = BookingResponse.model_validate(b).model_dump()
        res['server_time'] = now
        res['expires_at'] = b.created_at + timedelta(minutes=10)
        results.append(res)
    return results


@router.get("/{booking_id}", response_model=BookingDetailResponse)
def get_booking_details(
    booking_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get booking details"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this booking"
        )
    
    # Get payments
    from app.models.payment import Payment
    payments = db.query(Payment).filter(Payment.booking_id == booking_id).all()
    
    # Get check-ins
    from app.models.checkin import CheckIn
    check_ins = []
    for ticket in booking.tickets:
        check_in = db.query(CheckIn).filter(CheckIn.ticket_id == ticket.id).first()
        if check_in:
            check_ins.append({
                "id": check_in.id,
                "ticket_id": check_in.ticket_id,
                "checked_in_at": check_in.checked_in_at,
                "qr_code": check_in.qr_code
            })
    
    # Get flight info
    from app.models.flight import Flight
    from app.schemas.flight import FlightResponse
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    booking_response = BookingResponse.model_validate(booking).model_dump()
    booking_response['server_time'] = now
    booking_response['expires_at'] = booking.created_at + timedelta(minutes=10)
    
    return {
        **booking_response,
        "payments": [{
            "id": p.id,
            "amount": p.amount,
            "method": p.method.value,
            "status": p.status.value,
            "transaction_id": p.transaction_id,
            "created_at": p.created_at
        } for p in payments],
        "check_ins": check_ins,
        "flight": FlightResponse.model_validate(flight).model_dump()
    }


@router.get("/pnr/{pnr}", response_model=BookingDetailResponse)
def get_booking_by_pnr(
    pnr: str,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get booking by PNR code"""
    booking = db.query(Booking).filter(Booking.pnr == pnr).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this booking"
        )
    
    return get_booking_details(booking.id, current_user, db)


@router.put("/{booking_id}/cancel", response_model=BookingResponse)
def cancel_my_booking(
    booking_id: int,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """
    Cancel user's own booking.
    - HOLD: Can cancel any time.
    - CONFIRMED: Allowed if check-in hasn't started (24 hours before departure).
    """
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check ownership
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to cancel this booking"
        )
    
    # Check if already cancelled
    if booking.status == BookingStatus.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Booking is already cancelled"
        )
    
    # Get flight
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Associated flight not found"
        )
    
    now = datetime.utcnow()
    
    # Strict cancellation rules
    # 1. Check flight status
    # Cancellation allowed only if SCHEDULED or DELAYED.
    # Block if BOARDING, DEPARTED, LANDED, CANCELLED (though CANCELLED handled above differently)
    from app.models.flight import FlightStatus
    if flight.status in [FlightStatus.BOARDING, FlightStatus.DEPARTED, FlightStatus.LANDED]:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel booking: Flight is {flight.status.value}"
        )

    # 2. Check time window for CONFIRMED bookings (Locks when check-in starts - 60 mins)
    if booking.status == BookingStatus.CONFIRMED:
        # Use Bishkek time for consistency
        from zoneinfo import ZoneInfo
        kyrgyz_tz = ZoneInfo("Asia/Bishkek")
        now_kz = datetime.now(kyrgyz_tz).replace(tzinfo=None) # Naive for comparison if DB is naive
        # If DB stores naive time as local time:
        
        # NOTE: logic elsewhere assumes departure_time is effectively local. 
        # Check-in opens 24 hours before.
        check_in_start = flight.departure_time - timedelta(hours=24)
        
        # We need to make sure we compare apples to apples.
        # Assuming flight.departure_time is naive local time (as per other files)
        
        if now_kz >= check_in_start:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Check-in has started (24 hours before departure). Booking can no longer be cancelled."
            )
    
    # Release seat holds if any
    from app.models.booking import SeatHold
    db.query(SeatHold).filter(SeatHold.booking_id == booking_id).delete()
    
    # Logic for seat release from tickets
    for ticket in booking.tickets:
        ticket.seat_number = None
    
    # Cancel the booking
    booking.status = BookingStatus.CANCELLED
    db.commit()
    db.refresh(booking)
    
    return booking
