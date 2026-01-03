from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base
import uuid

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    role = Column(String, default="passenger")

class Airport(Base):
    __tablename__ = "airports"
    
    code = Column(String, primary_key=True, index=True)
    name = Column(String)
    city = Column(String)
    country = Column(String)

class Flight(Base):
    __tablename__ = "flights"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    flight_number = Column(String, index=True)
    origin_code = Column(String, ForeignKey("airports.code"), index=True)
    destination_code = Column(String, ForeignKey("airports.code"), index=True)
    departure_time = Column(String)  # ISO Format
    arrival_time = Column(String)
    price = Column(Float)
    
    origin = relationship("Airport", foreign_keys=[origin_code])
    destination = relationship("Airport", foreign_keys=[destination_code])

class Booking(Base):
    __tablename__ = "bookings"
    
    pnr = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4())[:6].upper())
    user_id = Column(String, ForeignKey("users.id"))
    flight_id = Column(String, ForeignKey("flights.id"))
    status = Column(String, default="PENDING") # PENDING, CONFIRMED, CANCELLED
    total_price = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    passengers = relationship("Passenger", back_populates="booking")

class Passenger(Base):
    __tablename__ = "passengers"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    booking_pnr = Column(String, ForeignKey("bookings.pnr"))
    first_name = Column(String)
    last_name = Column(String)
    passport_number = Column(String)
    seat_number = Column(String, nullable=True)
    
    booking = relationship("Booking", back_populates="passengers")
