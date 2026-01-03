from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from db.session import get_db
from core.dependencies import require_passenger
from models.flight import Flight
from models.booking import Booking
from models.seat_hold import SeatHold
from services.seat_hold_service import clear_expired_holds
from models.user import User
from schemas.booking import BookingCreate, BookingOut

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.get("/", response_model=List[BookingOut])
def get_user_bookings(
    db: Session = Depends(get_db),
    user: User = Depends(require_passenger),
):
    return db.query(Booking).filter(Booking.user_id == user.id).all()


@router.post("/", response_model=BookingOut)
def create_booking(
    booking_in: BookingCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_passenger),
):
    print(f"Creating booking for user {user.email}, flight {booking_in.flight_id}")
    flight_id = booking_in.flight_id
    seats = booking_in.seats
    
    # 1️⃣ Passenger Profile
    if not user.profile or not all([
        user.profile.full_name,
        user.profile.phone,
        user.profile.passport_number,
        user.profile.nationality,
        user.profile.date_of_birth
    ]):
        raise HTTPException(
            status_code=400,
            detail="Passenger profile is incomplete. Please ensure you have provided your full name, phone, passport, nationality, and date of birth."
        )

    # 2️⃣ Flight
    flight = db.query(Flight).filter_by(id=flight_id).first()
    if not flight:
        raise HTTPException(404, "Flight not found")

    # 3️⃣ Clear expired holds
    clear_expired_holds(db, flight_id)

    # 4️⃣ Check holds
    holds = (
        db.query(SeatHold)
        .filter(
            SeatHold.flight_id == flight_id,
            SeatHold.seat_number.in_(seats),
            SeatHold.user_id == user.id,
        )
        .all()
    )

    if len(holds) != len(seats):
        raise HTTPException(
            status_code=400,
            detail="All seats must be held before booking"
        )

    # 5️⃣ Tickets
    tickets_data = [
        {
            "passenger_name": user.profile.full_name,
            "passport_number": user.profile.passport_number,
            "nationality": user.profile.nationality,
            "seat_number": seat,
        }
        for seat in seats
    ]

    # 6️⃣ Create booking
    try:
        booking = Booking.create_booking(
            db=db,
            flight=flight,
            ticket_data=tickets_data,
            user_id=user.id
        )
    except ValueError as e:
        raise HTTPException(400, str(e))

    return booking
