import uuid
from datetime import datetime
from sqlalchemy.orm import Session
from fastapi import HTTPException

from models.checkin import CheckIn


class CheckInService:

    @staticmethod
    def check_in(
        db: Session,
        ticket_id: int,
    ) -> CheckIn:
        existing = db.query(CheckIn).filter(
            CheckIn.ticket_id == ticket_id
        ).first()

        if existing:
            raise HTTPException(400, "Already checked in")

        checkin = CheckIn(
            ticket_id=ticket_id,
            checked_in=True,
            boarding_pass_qr=str(uuid.uuid4()),
            checked_in_at=datetime.utcnow(),
        )

        db.add(checkin)
        db.commit()
        db.refresh(checkin)
        return checkin
