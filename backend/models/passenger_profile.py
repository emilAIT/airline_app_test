from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    passport_number = Column(String, unique=True, nullable=False)
    nationality = Column(String, nullable=False)
    date_of_birth = Column(String, nullable=False)  # ISO Format YYYY-MM-DD
    phone_number = Column(String)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="passenger_profile")
    tickets = relationship("Ticket", back_populates="passenger")

