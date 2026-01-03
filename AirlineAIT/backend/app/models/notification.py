"""
Notification model for user alerts.

Types: BOOKING_EXPIRED, BOOKING_CONFIRMED, FLIGHT_DELAY, FLIGHT_CANCELLED, etc.
Supports read/unread tracking per user.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
import enum
from datetime import datetime
from app.db.base import Base


class NotificationType(str, enum.Enum):
    BOOKING_EXPIRED = "BOOKING_EXPIRED"
    BOOKING_CONFIRMED = "BOOKING_CONFIRMED"
    FLIGHT_DELAY = "FLIGHT_DELAY"
    FLIGHT_CANCELLED = "FLIGHT_CANCELLED"
    FLIGHT_UPDATE = "FLIGHT_UPDATE"
    GENERAL = "GENERAL"


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(Enum(NotificationType), nullable=False, default=NotificationType.GENERAL)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="notifications")
