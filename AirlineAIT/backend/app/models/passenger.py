"""
PassengerProfile model.

Stores passenger travel documents: name, phone, passport, nationality, DOB.
Users can have multiple profiles (for family/group bookings).

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, Date, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    full_name = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    passport_number = Column(String, nullable=False)
    nationality = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="passenger_profiles")
    tickets = relationship("Ticket", back_populates="passenger", cascade="all, delete-orphan")

