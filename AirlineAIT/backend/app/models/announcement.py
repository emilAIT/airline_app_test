"""
Announcement model for flight updates.

Types: DELAY, CANCELLATION, GATE_CHANGE, BOARDING_STARTED, CHECKIN_OPEN, GENERAL.
Linked to flights to notify affected passengers.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum
from app.db.base import Base


class AnnouncementType(str, enum.Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING_STARTED = "BOARDING_STARTED"
    CHECKIN_OPEN = "CHECKIN_OPEN"
    GENERAL = "GENERAL"


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=True)
    type = Column(Enum(AnnouncementType), nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    
    # Relationships
    flight = relationship("Flight", back_populates="announcements")

