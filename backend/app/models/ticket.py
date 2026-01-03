"""Ticket model - individual passenger tickets within a booking."""

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Ticket(Base):
    """
    Individual ticket for a passenger.
    
    Each ticket belongs to a booking and represents one passenger + one seat.
    Ticket number format: "784" + 10 random digits (airline-style).
    
    Business Rules:
        - Links Passenger, Booking, and Seat (Exam Task requirement)
        - Unique constraint prevents double booking of same seat on same flight
    """
    __tablename__ = "tickets"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Ticket number: 13-digit format (784XXXXXXXXXX)
    ticket_number = Column(String(13), unique=True, nullable=False, index=True)
    
    # Foreign key to booking
    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Foreign key to flight (denormalized for constraint efficiency)
    # This ensures we can enforce unique seat per flight at DB level
    flight_id = Column(Integer, ForeignKey("flights.id", ondelete="CASCADE"), nullable=False, index=True)

    # Exam Task: explicit links
    passenger_id = Column(Integer, ForeignKey("passengers.id", ondelete="CASCADE"), nullable=False, index=True)
    seat_id = Column(Integer, ForeignKey("seats.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Passenger information (denormalized from profile at booking time)
    passenger_first_name = Column(String(100), nullable=False)
    passenger_last_name = Column(String(100), nullable=False)
    
    # Assigned seat
    seat_number = Column(String(10), nullable=False)
    
    # Price for this specific ticket (can vary by seat class)
    price = Column(Numeric(10, 2), nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    booking = relationship("Booking", back_populates="tickets")
    flight = relationship("Flight")
    passenger = relationship("BookingPassenger")
    seat = relationship("Seat", back_populates="tickets")
    checkin = relationship("CheckIn", back_populates="ticket", uselist=False, cascade="all, delete-orphan")
    
    # Constraints
    # CRITICAL: Unique constraint prevents double booking of same seat on same flight
    __table_args__ = (
        UniqueConstraint('flight_id', 'seat_number', name='uq_flight_seat_ticket'),
        UniqueConstraint('seat_id', name='uq_ticket_seat_id'),
        CheckConstraint('price >= 0', name='check_price_positive'),
    )
    
    def __repr__(self):
        return f"<Ticket(number='{self.ticket_number}', passenger='{self.passenger_first_name} {self.passenger_last_name}')>"
