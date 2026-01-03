from sqlalchemy.orm import Session
from app.models.all_models import Flight, Seat, SeatHold, SeatCategory
from datetime import datetime, timedelta, timezone
from typing import Optional
import json


def generate_seats_for_flight(db: Session, flight: Flight):
    """Generate seats for a flight based on airplane configuration"""
    # Check if seats already exist
    existing_seats = db.query(Seat).filter(Seat.flight_id == flight.id).count()
    if existing_seats > 0:
        return  # Seats already generated

    airplane = flight.airplane
    if not airplane or not airplane.seat_config:
        return

    try:
        config = json.loads(airplane.seat_config)
        rows = config.get("rows", 0)
        seats_per_row = config.get("seats_per_row", [3, 3])
        extra_legroom_rows = config.get("extra_legroom_rows", [])

        seats = []
        seat_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        for row in range(1, rows + 1):
            seat_letter_idx = 0
            for col_idx, seats_in_section in enumerate(seats_per_row):
                for seat_in_section in range(seats_in_section):
                    if seat_letter_idx >= len(seat_letters):
                        break
                    seat_letter = seat_letters[seat_letter_idx]
                    seat_number = f"{row}{seat_letter}"
                    category = SeatCategory.EXTRA_LEGROOM if row in extra_legroom_rows else SeatCategory.STANDARD

                    seat = Seat(
                        flight_id=flight.id,
                        seat_number=seat_number,
                        category=category,
                        is_available=True,
                        row=row,
                        column=seat_letter
                    )
                    seats.append(seat)
                    seat_letter_idx += 1

        db.add_all(seats)
        db.commit()
    except (json.JSONDecodeError, KeyError):
        # Fallback: create simple seats
        total_seats = airplane.total_seats
        seats = []
        seat_letters = "ABCDEFGH"
        for i in range(total_seats):
            row = (i // len(seat_letters)) + 1
            col = seat_letters[i % len(seat_letters)]
            seat_number = f"{row}{col}"
            seat = Seat(
                flight_id=flight.id,
                seat_number=seat_number,
                category=SeatCategory.STANDARD,
                is_available=True,
                row=row,
                column=col
            )
            seats.append(seat)
        db.add_all(seats)
        db.commit()


def is_seat_available(db: Session, flight_id: int, seat_number: str) -> bool:
    """Check if a seat is available (not booked and not held)"""
    # Ensure seats are generated for this flight
    from app.models.all_models import Flight
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if flight:
        generate_seats_for_flight(db, flight)

    # Check if seat exists and is marked as available
    seat = db.query(Seat).filter(
        Seat.flight_id == flight_id,
        Seat.seat_number == seat_number
    ).first()

    if not seat:
        return False

    if not seat.is_available:
        return False

    # Check if seat is currently held
    now = datetime.now(timezone.utc)
    active_hold = db.query(SeatHold).filter(
        SeatHold.flight_id == flight_id,
        SeatHold.seat_number == seat_number,
        SeatHold.held_until > now
    ).first()

    return active_hold is None


def hold_seat(db: Session, flight_id: int, seat_number: str, booking_id: int = None, hold_minutes: int = 10) -> SeatHold:
    """Hold a seat for a specified duration"""
    # Ensure seats are generated for this flight
    from app.models.all_models import Flight
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if flight:
        generate_seats_for_flight(db, flight)

    # Check if seat exists
    seat = db.query(Seat).filter(
        Seat.flight_id == flight_id,
        Seat.seat_number == seat_number
    ).first()

    if not seat:
        raise ValueError(
            f"Seat {seat_number} does not exist for this flight. Please select a different seat.")

    if not is_seat_available(db, flight_id, seat_number):
        # Provide more detailed error message
        if not seat.is_available:
            raise ValueError(f"Seat {seat_number} is already booked")
        # Check if held
        now = datetime.now(timezone.utc)
        active_hold = db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.seat_number == seat_number,
            SeatHold.held_until > now
        ).first()
        if active_hold:
            raise ValueError(
                f"Seat {seat_number} is currently held by another booking. Please try again in a few minutes or select a different seat.")
        raise ValueError(f"Seat {seat_number} is not available")

    held_until = datetime.now(timezone.utc) + timedelta(minutes=hold_minutes)
    seat_hold = SeatHold(
        flight_id=flight_id,
        seat_number=seat_number,
        booking_id=booking_id,
        held_until=held_until
    )
    db.add(seat_hold)
    db.commit()
    db.refresh(seat_hold)
    return seat_hold


def release_seat_hold(db: Session, seat_hold_id: int):
    """Release a seat hold"""
    seat_hold = db.query(SeatHold).filter(SeatHold.id == seat_hold_id).first()
    if seat_hold:
        db.delete(seat_hold)
        db.commit()


def cleanup_expired_holds(db: Session):
    """Remove expired seat holds"""
    now = datetime.now(timezone.utc)
    expired_holds = db.query(SeatHold).filter(SeatHold.held_until < now).all()
    for hold in expired_holds:
        db.delete(hold)
    db.commit()
    return len(expired_holds)


def mark_seat_unavailable(db: Session, flight_id: int, seat_number: str):
    """Mark a seat as unavailable (booked)"""
    seat = db.query(Seat).filter(
        Seat.flight_id == flight_id,
        Seat.seat_number == seat_number
    ).first()
    if seat:
        seat.is_available = False
        db.commit()


def auto_assign_seat(db: Session, flight_id: int) -> Optional[str]:
    """Auto-assign an available seat"""
    cleanup_expired_holds(db)
    seat = db.query(Seat).filter(
        Seat.flight_id == flight_id,
        Seat.is_available == True
    ).first()

    if seat:
        # Check if it's held
        now = datetime.now(timezone.utc)
        hold = db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.seat_number == seat.seat_number,
            SeatHold.held_until > now
        ).first()
        if not hold:
            return seat.seat_number
    return None
