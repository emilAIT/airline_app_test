"""
SeatTemplate model - defines seat layout for an airplane.
"""
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class SeatTemplate(Base):
    """
    Seat template for an airplane.
    
    Defines all available seats with their class (ECONOMY/BUSINESS/FIRST).
    Seat numbers follow airline format: row + letter (e.g., "12A", "1F").
    
    Unique constraint ensures no duplicate seats per airplane.
    """
    __tablename__ = "seat_templates"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    airplane_id = Column(Integer, ForeignKey("airplanes.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Seat number format: "12A", "1F", etc.
    seat_number = Column(String(10), nullable=False)
    
    # Seat class: ECONOMY, BUSINESS, or FIRST
    # Enforced at application level (Pydantic validation)
    seat_class = Column(String(20), nullable=False)
    
    # is_available: False if seat is broken/unavailable
    is_available = Column(Boolean, default=True, nullable=False)
    
    # Relationship to Airplane
    airplane = relationship("Airplane", back_populates="seat_templates")
    
    # Unique constraint: one seat number per airplane
    __table_args__ = (
        UniqueConstraint('airplane_id', 'seat_number', name='uq_airplane_seat'),
    )
    
    def __repr__(self):
        return f"<SeatTemplate(airplane_id={self.airplane_id}, seat='{self.seat_number}', class='{self.seat_class}')>"
