from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum, Float
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base

class BookingStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    pnr = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    status = Column(Enum(BookingStatus), default=BookingStatus.PENDING)
    created_at = Column(DateTime, nullable=False)
    total_price = Column(Float, nullable=False)

    flight = relationship("app.models.flight.Flight")
    tickets = relationship("Ticket", back_populates="booking")
    payment = relationship("Payment", back_populates="booking", uselist=False)

class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    passenger_name = Column(String, nullable=False)
    passport_number = Column(String, nullable=True)  # Added passport number
    seat_number = Column(String, nullable=False)
    ticket_number = Column(String, unique=True, index=True, nullable=False)
    
    booking = relationship("Booking", back_populates="tickets")
    check_in = relationship("CheckIn", back_populates="ticket", uselist=False)

class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"

class PaymentMethod(str, enum.Enum):
    CARD = "CARD"

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True, nullable=False)
    amount = Column(Float, nullable=False)
    method = Column(Enum(PaymentMethod), default=PaymentMethod.CARD)
    status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING)
    created_at = Column(DateTime, nullable=False)

    booking = relationship("Booking", back_populates="payment")

class CheckIn(Base):
    __tablename__ = "check_ins"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("tickets.id"), unique=True, nullable=False)
    check_in_time = Column(DateTime, nullable=False)
    
    ticket = relationship("Ticket", back_populates="check_in")

class SeatHold(Base):
    """Temporary seat reservation before booking creation - 10 minute timer"""
    __tablename__ = "seat_holds"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    seat_number = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    
    flight = relationship("app.models.flight.Flight")
    user = relationship("app.models.user.User")
