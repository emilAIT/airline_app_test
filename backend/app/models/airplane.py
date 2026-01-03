"""
Airplane model - aircraft in the fleet.
"""
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Airplane(Base):
    """
    Airplane in the airline fleet.
    
    Each airplane has a seat template defining available seats.
    """
    __tablename__ = "airplanes"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Unique registration number (e.g., "UP-B7701")
    registration_number = Column(String(20), unique=True, nullable=False, index=True)
    
    model = Column(String(100), nullable=False)  # e.g., "Boeing 737-800"
    manufacturer = Column(String(100))  # e.g., "Boeing"
    total_seats = Column(Integer, nullable=False)  # Total capacity
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    seat_templates = relationship("SeatTemplate", back_populates="airplane", cascade="all, delete-orphan")
    seats = relationship("Seat", back_populates="airplane", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Airplane(reg='{self.registration_number}', model='{self.model}')>"
