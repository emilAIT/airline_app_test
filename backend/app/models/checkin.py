"""
CheckIn model - passenger check-in and boarding pass generation.
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class CheckIn(Base):
    """
    Check-in record for a ticket.
    
    Business Rules:
        - One check-in per ticket (enforced by unique constraint)
        - Only CONFIRMED bookings can check-in
        - Generates QR code string for boarding pass
    
    QR Code Format: "QR:{flight_number}:{seat_number}:{ticket_number}"
    """
    __tablename__ = "checkins"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # One-to-one with ticket
    ticket_id = Column(Integer, ForeignKey("tickets.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    
    # When passenger checked in
    checked_in_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # QR code string for boarding pass
    boarding_pass_qr = Column(String(255), nullable=False)
    
    # Relationship to ticket
    ticket = relationship("Ticket", back_populates="checkin")
    
    def __repr__(self):
        return f"<CheckIn(ticket_id={self.ticket_id}, checked_in_at={self.checked_in_at})>"
