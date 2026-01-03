from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base


class SeatHold(Base):
    """
    Internal table for managing seat holds and preventing double booking.
    UNIQUE constraint on (flight_id, seat_number) prevents race conditions.
    """
    __tablename__ = "seat_holds"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    held_until = Column(DateTime, nullable=False)
    
    # UNIQUE constraint to prevent double booking at database level (SQLite-safe)
    __table_args__ = (
        UniqueConstraint('flight_id', 'seat_number', name='uix_flight_seat'),
    )
    
    # Relationships
    flight = relationship("Flight")
    booking = relationship("Booking")
