"""
SeatHold model - temporary seat reservations (10 minute hold).
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class SeatHold(Base):
    """
    Temporary seat hold to prevent double booking.
    
    Mechanism:
        1. When booking is created, seats are INSERT into seat_holds with held_until = NOW + 10 min
        2. UNIQUE constraint (flight_id, seat_number) prevents double booking
        3. Background task deletes expired holds where booking_id IS NULL
        4. After payment SUCCESS, booking_id is set (hold becomes permanent)
    
    This is the SINGLE SOURCE OF TRUTH for seat availability.
    
    Business Rules:
        - Hold duration: 10 minutes (configurable)
        - If payment not completed, hold is auto-deleted by cleanup task
        - Once booking_id is set, hold is permanent (won't be cleaned up)
    """
    __tablename__ = "seat_holds"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Flight and seat identification
    flight_id = Column(Integer, ForeignKey("flights.id", ondelete="CASCADE"), nullable=False, index=True)
    seat_number = Column(String(10), nullable=False)
    
    # Who holds the seat
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # NULL until payment confirmed, then set to booking.id
    # This prevents cleanup task from deleting confirmed holds
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="CASCADE"), nullable=True)
    
    # Expiration time for hold (NOW + 10 minutes)
    # Background task uses this to clean up expired holds
    held_until = Column(DateTime(timezone=True), nullable=False, index=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    flight = relationship("Flight", back_populates="seat_holds")
    user = relationship("User")
    booking = relationship("Booking", back_populates="seat_holds")
    
    # CRITICAL: Unique constraint prevents double booking
    # Only one hold can exist for (flight_id, seat_number) at any time
    __table_args__ = (
        UniqueConstraint('flight_id', 'seat_number', name='uq_flight_seat_hold'),
    )
    
    def __repr__(self):
        return f"<SeatHold(flight_id={self.flight_id}, seat='{self.seat_number}', held_until={self.held_until})>"
