"""Booking model - user flight reservations."""

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship, synonym
from app.database import Base


class Booking(Base):
    """
    Flight booking by a passenger.
    
    Status workflow:
        CREATED (seats on hold, 10 min) → CONFIRMED (after payment) → CHECKED_IN → CANCELLED
    
    PNR (Passenger Name Record): unique 6-character booking reference code.
    
    Business Rules:
        - Created with status=CREATED, seats are held for 10 minutes
        - After successful payment, status changes to CONFIRMED
        - If payment not completed within hold period, booking can be cancelled
    """
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # PNR: unique booking reference (6 chars, alphanumeric, uppercase)
    # Exam Task naming: pnr_code
    pnr_code = Column(String(6), unique=True, nullable=False, index=True)

    # Backward compatibility: lots of code uses Booking.pnr
    pnr = synonym("pnr_code")
    
    # Foreign keys
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False, index=True)
    
    # Pricing
    total_amount = Column(Numeric(10, 2), nullable=False)
    
    # Status: CREATED, CONFIRMED, CANCELLED, CHECKED_IN
    status = Column(String(20), nullable=False, default="CREATED", index=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    flight = relationship("Flight", back_populates="bookings")
    passengers = relationship(
        "BookingPassenger",
        back_populates="booking",
        cascade="all, delete-orphan",
    )
    tickets = relationship("Ticket", back_populates="booking", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="booking")
    seat_holds = relationship("SeatHold", back_populates="booking", cascade="all, delete-orphan")
    
    # Check constraints
    __table_args__ = (
        CheckConstraint('total_amount >= 0', name='check_total_amount_positive'),
        CheckConstraint(
            "status IN ('CREATED','CONFIRMED','CANCELLED','CHECKED_IN')",
            name="check_booking_status_valid",
        ),
    )
    
    def __repr__(self):
        return f"<Booking(pnr_code='{self.pnr_code}', status='{self.status}')>"
