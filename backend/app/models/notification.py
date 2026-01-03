"""
Notification model - notifications for passengers about flight announcements.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Notification(Base):
    """
    Notification for passenger about flight announcement.
    
    Business Rules:
        - Created when staff publishes announcement for flight
        - One notification per passenger per announcement
        - Passengers can mark as read
    """
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign keys
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id", ondelete="CASCADE"), nullable=False, index=True)
    announcement_id = Column(Integer, ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False)
    
    # Content
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(50), nullable=False)  # INFO, DELAY, GATE_CHANGE, CANCELLATION
    
    # Status
    is_read = Column(Boolean, default=False, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    read_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    user = relationship("User")
    flight = relationship("Flight")
    announcement = relationship("Announcement")
    
    def __repr__(self):
        return f"<Notification(user_id={self.user_id}, flight_id={self.flight_id}, type='{self.notification_type}')>"
