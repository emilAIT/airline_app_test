"""
Announcement model - flight announcements by staff.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Announcement(Base):
    """
    Flight announcement created by staff.
    
    Examples:
        - "Gate changed to B12"
        - "Flight delayed by 30 minutes"
        - "Boarding has started"
    
    Business Rules:
        - Only STAFF can create announcements
        - Passengers can view announcements for their flights
    """
    __tablename__ = "announcements"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign keys
    flight_id = Column(Integer, ForeignKey("flights.id", ondelete="CASCADE"), nullable= True, index=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)  # Staff user
    
    # Announcement content
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    announcement_type = Column(String(50), default="INFO", nullable=False)  # INFO, DELAY, GATE_CHANGE, CANCELLATION
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    
    # Relationships
    flight = relationship("Flight", back_populates="announcements")
    creator = relationship("User")
    
    def __repr__(self):
        return f"<Announcement(flight_id={self.flight_id}, title='{self.title}')>"
