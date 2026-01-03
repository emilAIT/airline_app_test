from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Enum as SQLEnum, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base
from .enums import UserRole, BookingStatus, FlightStatus, PaymentStatus, PaymentMethod, SeatCategory, AnnouncementType


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(SQLEnum(UserRole), nullable=False, default=UserRole.PASSENGER)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    passenger_profile = relationship("PassengerProfile", back_populates="user", uselist=False)


class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    full_name = Column(String, nullable=True)
    phone_number = Column(String, nullable=True)
    passport_number = Column(String, nullable=True)
    nationality = Column(String, nullable=True)
    date_of_birth = Column(DateTime, nullable=True)
    is_complete = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="passenger_profile")


class Airport(Base):
    __tablename__ = "airports"
    
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(3), unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)
    
    departing_flights = relationship("Flight", foreign_keys="Flight.origin_airport_id", back_populates="origin_airport")
    arriving_flights = relationship("Flight", foreign_keys="Flight.destination_airport_id", back_populates="destination_airport")


class Airplane(Base):
    __tablename__ = "airplanes"
    
    id = Column(Integer, primary_key=True, index=True)
    model = Column(String, nullable=False)
    registration = Column(String, unique=True, nullable=False)
    total_seats = Column(Integer, nullable=False)
    
    seat_template = relationship("SeatTemplate", back_populates="airplane", cascade="all, delete-orphan")
    flights = relationship("Flight", back_populates="airplane")


class SeatTemplate(Base):
    __tablename__ = "seat_templates"
    
    id = Column(Integer, primary_key=True, index=True)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    row_number = Column(Integer, nullable=False)
    seat_label = Column(String(2), nullable=False)  # A, B, C, D, E, F
    category = Column(SQLEnum(SeatCategory), nullable=False, default=SeatCategory.STANDARD)
    
    airplane = relationship("Airplane", back_populates="seat_template")
    
    __table_args__ = (UniqueConstraint('airplane_id', 'row_number', 'seat_label', name='_airplane_seat_uc'),)


class Flight(Base):
    __tablename__ = "flights"
    
    id = Column(Integer, primary_key=True, index=True)
    flight_number = Column(String, unique=True, index=True, nullable=False)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    origin_airport_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    destination_airport_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    departure_time = Column(DateTime, nullable=False)
    arrival_time = Column(DateTime, nullable=False)
    base_price = Column(Float, nullable=False)
    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)
    status = Column(SQLEnum(FlightStatus), nullable=False, default=FlightStatus.SCHEDULED)
    boarding_time = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    airplane = relationship("Airplane", back_populates="flights")
    origin_airport = relationship("Airport", foreign_keys=[origin_airport_id], back_populates="departing_flights")
    destination_airport = relationship("Airport", foreign_keys=[destination_airport_id], back_populates="arriving_flights")
    bookings = relationship("Booking", back_populates="flight")
    announcements = relationship("Announcement", back_populates="flight")
    seat_holds = relationship("SeatHold", back_populates="flight", cascade="all, delete-orphan")

    @property
    def duration_minutes(self):
        diff = self.arrival_time - self.departure_time
        return int(diff.total_seconds() / 60)


class Booking(Base):
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, index=True)
    pnr = Column(String(6), unique=True, index=True, nullable=False)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(SQLEnum(BookingStatus), nullable=False, default=BookingStatus.CREATED)
    total_price = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    flight = relationship("Flight", back_populates="bookings")
    user = relationship("User")
    tickets = relationship("Ticket", back_populates="booking", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="booking", uselist=False)


class Ticket(Base):
    __tablename__ = "tickets"
    
    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String, unique=True, index=True, nullable=False)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    passenger_name = Column(String, nullable=False)
    passport_number = Column(String, nullable=False)
    seat_number = Column(String, nullable=False)
    seat_category = Column(SQLEnum(SeatCategory), nullable=False)
    price = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    booking = relationship("Booking", back_populates="tickets")
    check_in = relationship("CheckIn", back_populates="ticket", uselist=False)


class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True, nullable=False)
    amount = Column(Float, nullable=False)
    method = Column(SQLEnum(PaymentMethod), nullable=False)
    status = Column(SQLEnum(PaymentStatus), nullable=False, default=PaymentStatus.PENDING)
    idempotency_key = Column(String, unique=True, index=True, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    paid_at = Column(DateTime, nullable=True)
    
    booking = relationship("Booking", back_populates="payment")


class CheckIn(Base):
    __tablename__ = "check_ins"
    
    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("tickets.id"), unique=True, nullable=False)
    checked_in_at = Column(DateTime, default=datetime.utcnow)
    qr_code = Column(String, nullable=False)
    
    ticket = relationship("Ticket", back_populates="check_in")


class Announcement(Base):
    __tablename__ = "announcements"
    
    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    type = Column(SQLEnum(AnnouncementType), nullable=False)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    flight = relationship("Flight", back_populates="announcements")


class SeatHold(Base):
    __tablename__ = "seat_holds"
    
    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)
    booking_id = Column(Integer, nullable=True)
    held_until = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    flight = relationship("Flight", back_populates="seat_holds")
    
    __table_args__ = (UniqueConstraint('flight_id', 'seat_number', name='_flight_seat_uc'),)

