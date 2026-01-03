from sqlalchemy import Boolean, Column, Integer, String, Enum, Date, ForeignKey
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base

class UserRole(str, enum.Enum):
    PASSENGER = "passenger"
    STAFF = "staff"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, index=True)
    role = Column(Enum(UserRole), default=UserRole.PASSENGER)
    is_active = Column(Boolean, default=True)

    profile = relationship("PassengerProfile", back_populates="user", uselist=False)
    notifications = relationship("app.models.flight.UserNotification", back_populates="user")

class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    phone_number = Column(String)
    passport_number = Column(String)
    nationality = Column(String)
    birth_date = Column(Date)

    user = relationship("User", back_populates="profile")
