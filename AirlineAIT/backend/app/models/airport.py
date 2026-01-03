"""
Airport model.

Stores airport information: IATA code, name, city, country.
Links to flights as origin or destination.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class Airport(Base):
    __tablename__ = "airports"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(3), unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Relationships
    departure_flights = relationship("Flight", foreign_keys="Flight.origin_airport_id", back_populates="origin_airport")
    arrival_flights = relationship("Flight", foreign_keys="Flight.destination_airport_id", back_populates="destination_airport")
    creator = relationship("User", foreign_keys=[created_by])


