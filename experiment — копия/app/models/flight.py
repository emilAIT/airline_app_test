from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float, Enum, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.core.database import Base

class FlightStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"

class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True)
    flight_number = Column(String, index=True, nullable=False)
    departure_airport_code = Column(String, ForeignKey("airports.code"), nullable=False)
    arrival_airport_code = Column(String, ForeignKey("airports.code"), nullable=False)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    departure_time = Column(DateTime, nullable=False)
    arrival_time = Column(DateTime, nullable=False)
    status = Column(Enum(FlightStatus), default=FlightStatus.SCHEDULED)
    base_price = Column(Float, nullable=False)
    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)

    airplane = relationship("app.models.aviation.Airplane", back_populates="flights")
    departure_airport = relationship("app.models.aviation.Airport", foreign_keys=[departure_airport_code])
    arrival_airport = relationship("app.models.aviation.Airport", foreign_keys=[arrival_airport_code])
    announcements = relationship("Announcement", back_populates="flight")

class AnnouncementType(str, enum.Enum):
    DELAY = "Delay"
    CANCELLATION = "Cancellation"
    GATE_CHANGE = "Gate Change"
    BOARDING_STARTED = "Boarding Started"
    GENERAL_INFO = "General Info"

class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)  # NULL = public announcement, not NULL = personal
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(Enum(AnnouncementType), default=AnnouncementType.GENERAL_INFO)
    created_at = Column(DateTime, nullable=False)

    flight = relationship("Flight", back_populates="announcements")
    user = relationship("app.models.user.User", foreign_keys=[user_id])

class UserNotificationType(str, enum.Enum):
    BOOKING_CONFIRMED = "Booking Confirmed"
    TICKET_PURCHASED = "Ticket Purchased"
    FLIGHT_UPDATE = "Flight Update"

class UserNotification(Base):
    __tablename__ = "user_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(Enum(UserNotificationType), nullable=False)
    message = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_read = Column(Boolean, default=False)  # отметка, прочитал ли пользователь

    user = relationship("app.models.user.User", back_populates="notifications")
