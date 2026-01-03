from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from db.session import get_db
from core.dependencies import require_passenger
from models.flight import Flight
from models.seat_hold import SeatHold
from services.seat_hold_service import clear_expired_holds

router = APIRouter(prefix="/seats", tags=["Seats"])


@router.post("/hold")
def hold_seat(
    flight_id: int,
    seat_number: str,
    db: Session = Depends(get_db),
    user = Depends(require_passenger),
):
    flight = db.query(Flight).filter_by(id=flight_id).first()
    if not flight:
        raise HTTPException(404, "Flight not found")

    # 🧼 очищаем старые HOLD
    clear_expired_holds(db, flight_id)

    # ❌ проверка: занято билетом
    occupied = {t.seat_number for t in flight.tickets}
    if seat_number in occupied:
        raise HTTPException(400, "Seat already booked")

    # ❌ проверка: уже HOLD
    existing_hold = (
        db.query(SeatHold)
        .filter_by(flight_id=flight_id, seat_number=seat_number)
        .first()
    )
    if existing_hold:
        raise HTTPException(400, "Seat is temporarily held")

    # ✅ создаём HOLD
    hold = SeatHold(
        flight_id=flight_id,
        seat_number=seat_number,
        user_id=user.id,
        expires_at=SeatHold.hold_expiry()
    )

    db.add(hold)
    db.commit()

    return {
        "status": "HELD",
        "expires_at": hold.expires_at
    }
