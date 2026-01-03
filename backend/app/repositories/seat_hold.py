"""SeatHold repository - CRITICAL for double booking prevention."""
from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, or_

from app.models.booking import Booking
from app.models.seat_hold import SeatHold


class SeatHoldRepository:
    """
    Data access layer for SeatHold.
    
    CRITICAL: The UNIQUE constraint on (flight_id, seat_number)
    is the single source of truth for preventing double booking.
    """
    
    def create(
        self,
        db: Session,
        flight_id: int,
        seat_number: str,
        user_id: int,
        held_until: datetime,
        booking_id: Optional[int] = None
    ) -> SeatHold:
        """
        Create seat hold.
        
        IntegrityError will be raised if seat already held (UNIQUE constraint).
        This is intentional - prevents double booking.
        """
        seat_hold = SeatHold(
            flight_id=flight_id,
            seat_number=seat_number,
            user_id=user_id,
            held_until=held_until,
            booking_id=booking_id
        )
        db.add(seat_hold)
        db.flush()  # Trigger DB constraint check immediately
        db.refresh(seat_hold)
        return seat_hold
    
    def get_active_held_seats(self, db: Session, flight_id: int, now: datetime) -> List[str]:
        """Get seat numbers currently held (not expired) for a flight.

        Holds are considered active when:
          - held_until > now
          - AND (booking_id is NULL) OR (booking.status == 'CREATED')
        """
        rows = (
            db.query(SeatHold.seat_number)
            .outerjoin(Booking, Booking.id == SeatHold.booking_id)
            .filter(SeatHold.flight_id == flight_id)
            .filter(SeatHold.held_until > now)
            .filter(and_(SeatHold.booking_id.is_(None)) | (Booking.status == "CREATED"))
            .all()
        )
        return [r[0] for r in rows]
    
    def link_to_booking(self, db: Session, flight_id: int, user_id: int, booking_id: int):
        """
        Link seat holds to confirmed booking after payment.
        
        Updates booking_id so cleanup task won't delete these holds.
        """
        db.query(SeatHold).filter(
            and_(
                SeatHold.flight_id == flight_id,
                SeatHold.user_id == user_id,
                SeatHold.booking_id.is_(None)
            )
        ).update({"booking_id": booking_id})
        db.flush()
    
    def delete_expired_holds(self, db: Session, now: datetime) -> int:
        """
        Delete expired seat holds (background task).
        
        Only deletes holds where booking_id IS NULL (unconfirmed).
        Returns count of deleted holds.
        """
        result = db.query(SeatHold).filter(
            and_(
                SeatHold.held_until < now,
                SeatHold.booking_id.is_(None)
            )
        ).delete()
        db.flush()
        return result

    def cancel_expired_created_bookings(self, db: Session, now: datetime) -> int:
        """Cancel CREATED bookings whose seat holds have expired.

        - booking.status: CREATED -> CANCELLED
        - deletes the expired seat_holds for that booking

        Returns number of bookings cancelled.
        """
        # Cancel if there are no active holds remaining for the booking.
        # This covers:
        #  - all holds expired
        #  - holds missing (shouldn't happen, but keeps state consistent)
        ids = (
            db.query(Booking.id)
            .outerjoin(SeatHold, SeatHold.booking_id == Booking.id)
            .filter(Booking.status == "CREATED")
            .group_by(Booking.id)
            .having(
                or_(
                    func.max(SeatHold.held_until).is_(None),
                    func.max(SeatHold.held_until) <= now,
                )
            )
            .all()
        )
        ids = [row[0] for row in ids if row and row[0] is not None]
        if not ids:
            return 0

        # Cancel bookings
        db.query(Booking).filter(Booking.id.in_(ids)).update({"status": "CANCELLED"}, synchronize_session=False)
        # Delete all holds for these bookings (expired or not) to release seats
        db.query(SeatHold).filter(SeatHold.booking_id.in_(ids)).delete(synchronize_session=False)
        db.flush()
        return len(ids)


seat_hold_repository = SeatHoldRepository()
