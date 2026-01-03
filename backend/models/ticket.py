from sqlalchemy import Column, Integer, String, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


class SeatCategory(str, enum.Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String, unique=True, nullable=False, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    passenger_profile_id = Column(Integer, ForeignKey("passenger_profiles.id"), nullable=False)
    seat_number = Column(String, nullable=False)  # e.g., "12A"
    seat_category = Column(SQLEnum(SeatCategory), default=SeatCategory.STANDARD)
    
    # Relationships
    booking = relationship("Booking", back_populates="tickets")
    passenger = relationship("PassengerProfile", back_populates="tickets")
    checkin = relationship("CheckIn", back_populates="ticket", uselist=False)
