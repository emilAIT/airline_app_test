"""Booking repository."""
from typing import List, Optional
from sqlalchemy.orm import Session, joinedload
from app.models.booking import Booking
from app.models.ticket import Ticket


class BookingRepository:
    """Data access layer for bookings."""
    
    def create(
        self,
        db: Session,
        pnr: str,
        user_id: int,
        flight_id: int,
        total_amount: float,
        status: str
    ) -> Booking:
        """Create booking."""
        booking = Booking(
            pnr=pnr,
            user_id=user_id,
            flight_id=flight_id,
            total_amount=total_amount,
            status=status
        )
        db.add(booking)
        db.flush()
        db.refresh(booking)
        return booking
    
    def get_by_id(self, db: Session, booking_id: int) -> Optional[Booking]:
        """Get booking by ID with relationships."""
        return (db.query(Booking)
                .options(
                    joinedload(Booking.passengers),
                    joinedload(Booking.tickets).joinedload(Ticket.seat),
                    joinedload(Booking.flight),
                    joinedload(Booking.seat_holds),
                )
                .filter(Booking.id == booking_id)
                .first())
    
    def get_by_pnr(self, db: Session, pnr: str) -> Optional[Booking]:
        """Get booking by PNR."""
        return (db.query(Booking)
                .options(
                    joinedload(Booking.passengers),
                    joinedload(Booking.tickets).joinedload(Ticket.seat),
                    joinedload(Booking.flight),
                    joinedload(Booking.seat_holds),
                )
                .filter(Booking.pnr == pnr.upper())
                .first())
    
    def get_user_bookings(self, db: Session, user_id: int) -> List[Booking]:
        """Get all bookings for a user."""
        return (db.query(Booking)
                .options(
                    joinedload(Booking.flight),
                    joinedload(Booking.passengers),
                    joinedload(Booking.tickets).joinedload(Ticket.seat),
                    joinedload(Booking.seat_holds),
                )
                .filter(Booking.user_id == user_id)
                .order_by(Booking.created_at.desc())
                .all())
    
    def update_status(self, db: Session, booking: Booking, new_status: str) -> Booking:
        """Update booking status."""
        booking.status = new_status
        db.flush()
        db.refresh(booking)
        return booking


booking_repository = BookingRepository()
