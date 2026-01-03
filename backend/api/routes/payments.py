from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from db.session import get_db
from core.dependencies import require_passenger
from models.booking import Booking
from models.seat_hold import SeatHold
from models.user import User

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/confirm")
def confirm_payment(
    booking_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_passenger),
):
    # 1️⃣ Находим бронирование
    booking = db.query(Booking).filter_by(id=booking_id).first()
    if not booking:
        raise HTTPException(404, "Booking not found")

    # 2️⃣ Проверка владельца
    if booking.user_id != user.id:
        raise HTTPException(403, "Not your booking")

    # 3️⃣ Проверка статуса
    if booking.status != "PENDING":
        raise HTTPException(400, "Booking already processed")

    # 4️⃣ ❗ Здесь должна быть реальная платёжка
    # Сейчас считаем, что платёж успешен

    # 5️⃣ Подтверждаем бронирование
    booking.status = "CONFIRMED"
    db.commit()

    # 6️⃣ Удаляем HOLD для этого рейса
    db.query(SeatHold).filter_by(
        flight_id=booking.flight_id,
        user_id=user.id
    ).delete()

    db.commit()

    return {
        "status": "PAID",
        "booking_id": booking.id
    }
