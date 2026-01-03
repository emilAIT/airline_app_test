"""
PassengerProfile model - required information for booking flights.
"""
from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class PassengerProfile(Base):
    """
    Passenger profile with personal information.
    
    Business Rule:
        User cannot create bookings without completing their profile.
        This is enforced in BookingService.
    """
    __tablename__ = "passenger_profiles"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # One-to-one relationship with User
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    
    # Personal information
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    date_of_birth = Column(Date)
    passport_number = Column(String(50))
    nationality = Column(String(100))
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationship to User
    user = relationship("User", back_populates="profile")
    
    def __repr__(self):
        return f"<PassengerProfile(id={self.id}, name='{self.first_name} {self.last_name}')>"
