"""
Booking, Ticket, and SeatHold models.

Booking: Ties user to flight with PNR, status (HOLD, CONFIRMED, CANCELLED, EXPIRED).
Ticket: Individual passenger tickets within a booking.
SeatHold: Temporary seat reservations during booking process.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, Float, Boolean
from sqlalchemy.orm import relationship
import enum
from typing import Optional
from app.db.base import Base


class BookingStatus(str, enum.Enum):
    HOLD = "HOLD"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"
    EXPIRED = "EXPIRED"


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    pnr = Column(String, unique=True, nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    status = Column(Enum(BookingStatus), default=BookingStatus.HOLD, nullable=False)
    created_at = Column(DateTime, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="bookings")
    flight = relationship("Flight", back_populates="bookings")
    tickets = relationship("Ticket", back_populates="booking", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="booking", cascade="all, delete-orphan")


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String, unique=True, nullable=False, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    passenger_profile_id = Column(Integer, ForeignKey("passenger_profiles.id"), nullable=False)
    seat_number = Column(String, nullable=True)  # e.g., "12A"
    price = Column(Float, nullable=True)  # Fixed price at booking time
    
    # Relationships
    booking = relationship("Booking", back_populates="tickets")
    passenger = relationship("PassengerProfile", back_populates="tickets")
    check_in = relationship("CheckIn", back_populates="ticket", uselist=False, cascade="all, delete-orphan")

    @property
    def passenger_name(self) -> Optional[str]:
        return self.passenger.full_name if self.passenger else None

    @property
    def is_checked_in(self) -> bool:
        return self.check_in is not None


class SeatHold(Base):
    __tablename__ = "seat_holds"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)
    held_until = Column(DateTime, nullable=False)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    
    # Relationships
    flight = relationship("Flight", back_populates="seat_holds")
    booking = relationship("Booking", backref="seat_holds")

