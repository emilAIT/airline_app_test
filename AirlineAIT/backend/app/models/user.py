"""
User model with role-based access control.

Defines UserRole enum (PASSENGER, STAFF, ADMIN) and User entity.
Staff users require admin approval (is_approved flag).
Staff can be assigned to specific airplanes.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, Boolean, Enum, ForeignKey
from sqlalchemy.orm import relationship
import enum
from app.db.base import Base


class UserRole(str, enum.Enum):
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"
    ADMIN = "ADMIN"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.PASSENGER, nullable=False)
    is_active = Column(Boolean, default=True)
    is_approved = Column(Boolean, default=True)  # False for new STAFF registrations
    assigned_airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=True)
    
    # Relationships
    passenger_profiles = relationship("PassengerProfile", back_populates="user", cascade="all, delete-orphan")
    bookings = relationship("Booking", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    assigned_airplane = relationship("Airplane", foreign_keys=[assigned_airplane_id])

