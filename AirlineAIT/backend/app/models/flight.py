"""
Flight model with status tracking.

Defines FlightStatus enum (SCHEDULED, BOARDING, DELAYED, CANCELLED, DEPARTED, LANDED).
Flights connect airports, use airplanes, and have category-based pricing.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, Enum
from sqlalchemy.orm import relationship
import enum
from app.db.base import Base


class FlightStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True)
    flight_number = Column(String, unique=True, nullable=False, index=True)
    origin_airport_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    destination_airport_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    departure_time = Column(DateTime, nullable=False)
    arrival_time = Column(DateTime, nullable=False)
    price = Column(Float, nullable=False)
    category_prices = Column(String, nullable=True)  # JSON string: {"BUSINESS": 500, "EXTRA_LEGROOM": 350}
    category_allocations = Column(String, nullable=True)  # JSON string: {"BUSINESS": 10, "EXTRA_LEGROOM": 20}
    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)
    status = Column(Enum(FlightStatus), default=FlightStatus.SCHEDULED, nullable=False)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    # Relationships
    origin_airport = relationship("Airport", foreign_keys=[origin_airport_id], back_populates="departure_flights")
    destination_airport = relationship("Airport", foreign_keys=[destination_airport_id], back_populates="arrival_flights")
    airplane = relationship("Airplane", back_populates="flights")
    bookings = relationship("Booking", back_populates="flight", cascade="all, delete-orphan")
    announcements = relationship("Announcement", back_populates="flight", cascade="all, delete-orphan")
    seat_holds = relationship("SeatHold", back_populates="flight", cascade="all, delete-orphan")
    creator = relationship("User", foreign_keys=[created_by])

