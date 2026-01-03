from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class BookingStatus(str, enum.Enum):
    CREATED = "CREATED"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    pnr = Column(String, unique=True, nullable=False, index=True)  # Passenger Name Record
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    status = Column(SQLEnum(BookingStatus), default=BookingStatus.CREATED)
    held_until = Column(DateTime)  # Renamed from seat_hold_expires_at, 10 minutes hold
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="bookings")
    flight = relationship("Flight", back_populates="bookings")
    tickets = relationship("Ticket", back_populates="booking", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="booking", uselist=False)
