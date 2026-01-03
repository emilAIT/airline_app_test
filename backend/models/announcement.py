from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class AnnouncementType(str, enum.Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING_STARTED = "BOARDING_STARTED"
    GENERAL = "GENERAL"


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    announcement_type = Column(SQLEnum(AnnouncementType), nullable=False)
    message = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    flight = relationship("Flight", back_populates="announcements")
