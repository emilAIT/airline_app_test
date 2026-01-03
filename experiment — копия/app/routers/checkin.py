from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.routers import deps
from app.models import user as user_model
from app.models import booking as booking_model
from app.models import flight as flight_model

router = APIRouter()

@router.post("/{booking_id}/checkin", response_model=List[dict])
def check_in(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    booking = db.query(booking_model.Booking).filter(
        booking_model.Booking.id == booking_id,
        booking_model.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != booking_model.BookingStatus.CONFIRMED:
        raise HTTPException(status_code=400, detail="Booking not confirmed")
        
    flight = booking.flight
    now = datetime.utcnow()
    departure = flight.departure_time
    
    # Check window: 24h to 1h before
    time_until_departure = departure - now
    check_in_start = departure - timedelta(hours=24)
    check_in_end = departure - timedelta(hours=1)
    
    if now < check_in_start:
        hours_until_checkin = (check_in_start - now).total_seconds() / 3600
        raise HTTPException(
            status_code=400, 
            detail=f"Check-in will be available in {hours_until_checkin:.1f} hours (24 hours before departure)"
        )
    elif now > check_in_end:
        if time_until_departure.total_seconds() < 0:
            raise HTTPException(status_code=400, detail="Flight has already departed")
        else:
            raise HTTPException(
                status_code=400, 
                detail="Check-in is no longer available (must be done at least 1 hour before departure)"
            )
        
    boarding_passes = []
    
    # Check if this is first check-in for this booking
    is_first_checkin = all(not ticket.check_in for ticket in booking.tickets)
    
    for ticket in booking.tickets:
        if not ticket.check_in:
            check_in_record = booking_model.CheckIn(
                ticket_id=ticket.id,
                check_in_time=now
            )
            db.add(check_in_record)
        
        # Generate payload
        qr_payload = f"{booking.pnr}|{flight.flight_number}|{ticket.seat_number}|{ticket.passenger_name}"
        boarding_passes.append({
            "passenger": ticket.passenger_name,
            "seat": ticket.seat_number,
            "flight": flight.flight_number,
            "gate": flight.gate or "TBD",
            "boarding_time": flight.departure_time - timedelta(minutes=40), # Mock 40 min before
            "qr_code": qr_payload
        })
    
    # Removed check-in announcement - user only wants booking and payment notifications
    db.commit()
    return boarding_passes

@router.get("/{booking_id}/boarding-pass", response_model=List[dict])
def get_boarding_pass(
    booking_id: int,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    # Same as above but read-only
    booking = db.query(booking_model.Booking).filter(
        booking_model.Booking.id == booking_id,
        booking_model.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    flight = booking.flight
    boarding_passes = []
    
    for ticket in booking.tickets:
        if ticket.check_in:
             qr_payload = f"{booking.pnr}|{flight.flight_number}|{ticket.seat_number}|{ticket.passenger_name}"
             boarding_passes.append({
                "passenger": ticket.passenger_name,
                "seat": ticket.seat_number,
                "flight": flight.flight_number,
                "gate": flight.gate or "TBD",
                "boarding_time": flight.departure_time - timedelta(minutes=40),
                "qr_code": qr_payload
            })
    
    if not boarding_passes:
        raise HTTPException(status_code=400, detail="Not checked in yet")
        
    return boarding_passes
