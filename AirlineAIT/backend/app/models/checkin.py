"""
CheckIn model.

Records passenger check-in with timestamp and QR boarding pass code.
One-to-one relationship with Ticket.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class CheckIn(Base):
    __tablename__ = "check_ins"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("tickets.id"), unique=True, nullable=False)
    checked_in_at = Column(DateTime, nullable=False)
    qr_code = Column(String, nullable=False)
    
    # Relationships
    ticket = relationship("Ticket", back_populates="check_in")

