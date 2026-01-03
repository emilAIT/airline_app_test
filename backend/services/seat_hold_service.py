from datetime import datetime
from sqlalchemy.orm import Session
from models.seat_hold import SeatHold


def clear_expired_holds(db: Session, flight_id: int):
    db.query(SeatHold).filter(
        SeatHold.flight_id == flight_id,
        SeatHold.expires_at < datetime.utcnow()
    ).delete()
    db.commit()
