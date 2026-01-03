from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class FlightStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"  # Changed from ARRIVED per instructions.txt


class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True)
    flight_number = Column(String, unique=True, nullable=False, index=True)
    origin_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    destination_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    scheduled_departure = Column(DateTime, nullable=False)
    scheduled_arrival = Column(DateTime, nullable=False)
    gate = Column(String)
    terminal = Column(String)
    price = Column(Float, nullable=False)  # Added for search results
    status = Column(SQLEnum(FlightStatus), default=FlightStatus.SCHEDULED)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    origin_airport = relationship("Airport", foreign_keys=[origin_id], back_populates="origin_flights")
    destination_airport = relationship("Airport", foreign_keys=[destination_id], back_populates="destination_flights")
    airplane = relationship("Airplane", back_populates="flights")
    bookings = relationship("Booking", back_populates="flight")
    announcements = relationship("Announcement", back_populates="flight")
