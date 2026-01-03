"""Bookings API routes."""

from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.core.exceptions import NotFound, ValidationError
from app.models.checkin import CheckIn
from app.models.flight import Flight
from app.models.ticket import Ticket
from app.models.user import User
from app.schemas.booking import BookingCreate, BookingResponse, PassengerInfo, TicketInfo
from app.services.booking_service import booking_service, PassengerData
from app.repositories.booking import booking_repository
from app.repositories.seat_hold import seat_hold_repository

router = APIRouter()


class BookingCheckInItem(BaseModel):
    ticket_number: str
    seat_number: str
    passenger_name: str
    flight_number: str
    gate: Optional[str] = None
    boarding_time: str
    boarding_pass_qr: str
    checked_in_at: str


class BookingCheckInResponse(BaseModel):
    booking_id: int
    pnr: str
    status: str
    items: List[BookingCheckInItem]


def _build_passenger_infos(booking) -> List[PassengerInfo]:
    # Prefer persisted booking passengers (full data captured at booking time)
    passengers = getattr(booking, "passengers", None) or []
    if passengers:
        infos: List[PassengerInfo] = []
        for p in passengers:
            ticket_number = next(
                (t.ticket_number for t in (booking.tickets or []) if t.seat_number == p.seat_number),
                "",
            )
            infos.append(
                PassengerInfo(
                    first_name=p.first_name,
                    last_name=p.last_name,
                    seat_number=p.seat_number,
                    ticket_number=ticket_number,
                    passport_number=p.passport_number,
                    nationality=p.nationality,
                    date_of_birth=p.date_of_birth,
                )
            )
        return infos

    # Fallback for legacy data: derive from tickets only (no passport/nationality/DOB)
    return [
        PassengerInfo(
            first_name=t.passenger_first_name,
            last_name=t.passenger_last_name,
            seat_number=t.seat_number,
            ticket_number=t.ticket_number,
            passport_number=None,
            nationality=None,
            date_of_birth=None,
        )
        for t in (booking.tickets or [])
    ]


@router.post("", response_model=BookingResponse, status_code=201)
def create_booking(
    data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create new booking with seat holds.
    
    - Validates passenger profile exists
    - Validates flight status
    - Creates seat holds (10 min expiration)
    - Prevents double booking via DB UNIQUE constraint
    
    Seats held for 10 minutes - must complete payment within this time.
    """
    passengers = [
        PassengerData(
            p.first_name, 
            p.last_name, 
            p.seat_number,
            p.passport_number,
            p.nationality,
            p.date_of_birth
        )
        for p in data.passengers
    ]
    
    booking = booking_service.create_booking(
        db=db,
        user_id=current_user.id,
        flight_id=data.flight_id,
        passengers=passengers
    )
    
    seats_held_until = None
    if booking.status == "CREATED" and booking.seat_holds:
        seats_held_until = max(h.held_until for h in booking.seat_holds)
    
    return BookingResponse(
        id=booking.id,
        booking_id=booking.id,
        pnr=booking.pnr,
        flight_id=booking.flight_id,
        total_amount=booking.total_amount,
        status=booking.status,
        created_at=booking.created_at,
        seats_held_until=seats_held_until,
        tickets=[TicketInfo.model_validate(t) for t in booking.tickets],
        passengers=_build_passenger_infos(booking),
    )


@router.get("/my", response_model=List[BookingResponse])
def get_my_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all bookings for current user."""
    # Auto-cancel expired CREATED bookings so seats are released even if the user
    # never attempts payment (holds expire after 10 minutes).
    seat_hold_repository.cancel_expired_created_bookings(db, datetime.utcnow())
    db.commit()

    bookings = booking_repository.get_user_bookings(db, current_user.id)
    
    result = []
    for booking in bookings:
        seats_held_until = None
        if booking.status == "CREATED" and booking.seat_holds:
            seats_held_until = max(h.held_until for h in booking.seat_holds)
        
        result.append(BookingResponse(
            id=booking.id,
            booking_id=booking.id,
            pnr=booking.pnr,
            flight_id=booking.flight_id,
            total_amount=booking.total_amount,
            status=booking.status,
            created_at=booking.created_at,
            seats_held_until=seats_held_until,
            tickets=[TicketInfo.model_validate(t) for t in booking.tickets],
            passengers=_build_passenger_infos(booking),
        ))
    
    return result


@router.get("/{pnr}", response_model=BookingResponse)
def get_booking_by_pnr(
    pnr: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get booking by PNR (only own bookings for passengers)."""
    booking = booking_repository.get_by_pnr(db, pnr)
    
    if not booking:
        raise NotFound("Booking")
    
    # Passengers can only see their own bookings
    if current_user.role == "PASSENGER" and booking.user_id != current_user.id:
        raise NotFound("Booking")
    
    seats_held_until = None
    if booking.status == "CREATED" and booking.seat_holds:
        seats_held_until = max(h.held_until for h in booking.seat_holds)
    
    return BookingResponse(
        id=booking.id,
        booking_id=booking.id,
        pnr=booking.pnr,
        flight_id=booking.flight_id,
        total_amount=booking.total_amount,
        status=booking.status,
        created_at=booking.created_at,
        seats_held_until=seats_held_until,
        tickets=[TicketInfo.model_validate(t) for t in booking.tickets],
        passengers=_build_passenger_infos(booking),
    )


@router.post("/{booking_id}/check-in", response_model=BookingCheckInResponse)
def check_in_booking(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Check-in all tickets in a booking.

    Exam Task endpoint:
      POST /bookings/{id}/check-in

    Rules:
      - Booking must belong to the user (PASSENGER)
      - Booking must be CONFIRMED
      - Check-in window: 24h to 1h before departure
      - Creates CheckIn records per ticket (idempotent-ish)
      - Updates booking.status to CHECKED_IN
    """
    booking = booking_repository.get_by_id(db, booking_id)
    if not booking:
        raise NotFound("Booking")

    if current_user.role == "PASSENGER" and booking.user_id != current_user.id:
        raise NotFound("Booking")

    if booking.status != "CONFIRMED" and booking.status != "CHECKED_IN":
        raise ValidationError(
            f"Cannot check-in: booking status is {booking.status}. Only CONFIRMED bookings can check-in."
        )

    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    if not flight:
        raise NotFound("Flight")

    now = datetime.utcnow()
    checkin_opens = flight.departure_time - timedelta(hours=24)
    checkin_closes = flight.departure_time - timedelta(hours=1)

    if now < checkin_opens:
        hours_until_open = int((checkin_opens - now).total_seconds() / 3600)
        raise ValidationError(
            f"Check-in not yet available. Opens 24 hours before departure (in {hours_until_open} hours)."
        )
    if now > checkin_closes:
        raise ValidationError("Check-in window closed. Check-in closes 1 hour before departure.")

    tickets = db.query(Ticket).filter(Ticket.booking_id == booking.id).all()
    if not tickets:
        raise NotFound("Ticket")

    items: List[BookingCheckInItem] = []
    for t in tickets:
        existing = db.query(CheckIn).filter(CheckIn.ticket_id == t.id).first()
        if existing:
            checkin = existing
        else:
            qr_code = f"QR:{flight.flight_number}:{t.seat_number}:{t.ticket_number}"
            checkin = CheckIn(ticket_id=t.id, boarding_pass_qr=qr_code)
            db.add(checkin)
            db.flush()
            db.refresh(checkin)

        passenger_name = f"{t.passenger_first_name} {t.passenger_last_name}"
        items.append(
            BookingCheckInItem(
                ticket_number=t.ticket_number,
                seat_number=t.seat_number,
                passenger_name=passenger_name,
                flight_number=flight.flight_number,
                gate=flight.gate,
                boarding_time=(flight.departure_time - timedelta(minutes=30)).isoformat(),
                boarding_pass_qr=checkin.boarding_pass_qr,
                checked_in_at=checkin.checked_in_at.isoformat(),
            )
        )

    # Update booking status
    if booking.status != "CHECKED_IN":
        booking_repository.update_status(db, booking, "CHECKED_IN")
    db.commit()

    return BookingCheckInResponse(
        booking_id=booking.id,
        pnr=booking.pnr,
        status=booking.status,
        items=items,
    )
