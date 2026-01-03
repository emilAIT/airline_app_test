from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Airport(Base):
    __tablename__ = "airports"

    code = Column(String, primary_key=True, index=True) # IATA code
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)

class Airplane(Base):
    __tablename__ = "airplanes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True) # Registration number
    model = Column(String, nullable=False)
    
    seats = relationship("Seat", back_populates="airplane", cascade="all, delete-orphan")
    flights = relationship("Flight", back_populates="airplane")

class Seat(Base):
    __tablename__ = "seats"

    id = Column(Integer, primary_key=True, index=True)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    seat_number = Column(String, nullable=False) # e.g. "12A"
    category = Column(String, nullable=False) # "Business", "Economy"

    airplane = relationship("Airplane", back_populates="seats")
