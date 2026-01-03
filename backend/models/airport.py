from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class Airport(Base):
    __tablename__ = "airports"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)  # e.g., "JFK", "LAX"
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)
    
    # Relationships
    origin_flights = relationship("Flight", foreign_keys="Flight.origin_id", back_populates="origin_airport")
    destination_flights = relationship("Flight", foreign_keys="Flight.destination_id", back_populates="destination_airport")

