import enum
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Float, Enum as SQLEnum, Text, Date, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from datetime import datetime, timezone

# --- ENUMS ---


class UserRole(str, enum.Enum):
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"


class BookingStatus(str, enum.Enum):
    CREATED = "CREATED"       # Booking created, seats held (10 min)
    CONFIRMED = "CONFIRMED"    # Payment successful
    CANCELLED = "CANCELLED"    # User cancelled
    EXPIRED = "EXPIRED"        # Hold timer expired, unpaid
    REFUNDED = "REFUNDED"      # Booking cancelled and refunded
    COMPLETED = "COMPLETED"    # Flight departed


class FlightStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class PaymentMethod(str, enum.Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


class AnnouncementType(str, enum.Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING_STARTED = "BOARDING_STARTED"
    GENERAL = "GENERAL"
    BOARDING_SOON = "BOARDING_SOON"
    FINAL_CALL = "FINAL_CALL"
    SECURITY = "SECURITY"
    CHECK_IN = "CHECK_IN"
    ARRIVAL = "ARRIVAL"


class AnnouncementPriority(str, enum.Enum):
    HIGH = "HIGH"    # Red (Cancellation, Final Call, Gate Change)
    MEDIUM = "MEDIUM" # Amber (Delay, Boarding Started)
    LOW = "LOW"      # Cyan (Info, Reminder)


class SeatCategory(str, enum.Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"

# --- MODELS ---


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    role = Column(SQLEnum(UserRole), default=UserRole.PASSENGER)

    # Relationships
    bookings = relationship("Booking", back_populates="user")
    passenger_profile = relationship(
        "PassengerProfile", back_populates="user", uselist=False)
    notifications = relationship("Notification", back_populates="user")


class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    passport_number = Column(String, index=True)
    phone_number = Column(String)
    nationality = Column(String)
    date_of_birth = Column(Date)

    user = relationship("User", back_populates="passenger_profile")


class Airport(Base):
    __tablename__ = "airports"

    id = Column(Integer, primary_key=True, index=True)
    # IATA code (e.g., FRU, DXB)
    code = Column(String(3), unique=True, index=True)
    name = Column(String)
    city = Column(String)
    country = Column(String)
    image_url = Column(String, nullable=True) # Added image URL field


class Airplane(Base):
    __tablename__ = "airplanes"

    id = Column(Integer, primary_key=True, index=True)
    model = Column(String)  # e.g., "Boeing 737"
    total_seats = Column(Integer)
    seat_config = Column(Text)  # JSON string with layout: "3-3", rows, etc.

    flights = relationship("Flight", back_populates="airplane")


class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True)
    flight_number = Column(String, unique=True, index=True)  # SU-123

    origin_id = Column(Integer, ForeignKey("airports.id"))
    destination_id = Column(Integer, ForeignKey("airports.id"))
    airplane_id = Column(Integer, ForeignKey("airplanes.id"))

    departure_time = Column(DateTime, nullable=False)
    arrival_time = Column(DateTime, nullable=False)
    base_price = Column(Float, nullable=False)
    status = Column(SQLEnum(FlightStatus), default=FlightStatus.SCHEDULED)
    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)

    # Relationships
    airplane = relationship("Airplane", back_populates="flights")
    origin = relationship("Airport", foreign_keys=[origin_id])
    destination = relationship("Airport", foreign_keys=[destination_id])
    bookings = relationship("Booking", back_populates="flight")
    seats = relationship("Seat", back_populates="flight",
                         cascade="all, delete-orphan")
    announcements = relationship("Announcement", back_populates="flight")


class Booking(Base):
    __tablename__ = "bookings"
    __table_args__ = (
        Index('idx_bookings_status', 'status'),
        Index('idx_bookings_hold_until', 'status', 'hold_until'),
    )

    id = Column(Integer, primary_key=True, index=True)
    pnr = Column(String(6), unique=True, index=True)  # Booking Reference
    user_id = Column(Integer, ForeignKey("users.id"))
    flight_id = Column(Integer, ForeignKey("flights.id"))
    status = Column(SQLEnum(BookingStatus), default=BookingStatus.CREATED)
    hold_until = Column(DateTime(timezone=True), nullable=True)  # 10-min hold timer
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="bookings")
    flight = relationship("Flight", back_populates="bookings")
    tickets = relationship("Ticket", back_populates="booking")
    payment = relationship("Payment", back_populates="booking", uselist=False)
    seat_holds = relationship(
        "SeatHold", foreign_keys="SeatHold.booking_id", back_populates="booking")


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    seat_number = Column(String)  # "12A"
    passenger_name = Column(String)
    # Unique ticket number
    ticket_number = Column(String, unique=True, index=True)

    booking = relationship("Booking", back_populates="tickets")
    check_in = relationship("CheckIn", back_populates="ticket", uselist=False)


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True)
    amount = Column(Float)
    currency = Column(String, default="USD")
    method = Column(SQLEnum(PaymentMethod))
    status = Column(SQLEnum(PaymentStatus), default=PaymentStatus.PENDING)
    transaction_id = Column(String, unique=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    booking = relationship("Booking", back_populates="payment")


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"),
                       nullable=True)  # Null if global
    type = Column(SQLEnum(AnnouncementType), default=AnnouncementType.GENERAL)
    priority = Column(SQLEnum(AnnouncementPriority), default=AnnouncementPriority.LOW)
    title = Column(String)
    message = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    effective_from = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)

    flight = relationship("Flight", back_populates="announcements")


class Seat(Base):
    __tablename__ = "seats"

    id = Column(Integer, primary_key=True, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)  # "12A"
    category = Column(SQLEnum(SeatCategory), default=SeatCategory.STANDARD)
    is_available = Column(Boolean, default=True)
    row = Column(Integer)
    column = Column(String)  # "A", "B", "C", etc.

    flight = relationship("Flight", back_populates="seats")


class SeatHold(Base):
    __tablename__ = "seat_holds"
    __table_args__ = (
        Index('idx_seat_holds_expires_at', 'held_until'),
    )

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)
    held_until = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    booking = relationship("Booking", foreign_keys=[booking_id])


class CheckIn(Base):
    __tablename__ = "check_ins"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("tickets.id"), unique=True)
    checked_in_at = Column(DateTime(timezone=True), server_default=func.now())
    boarding_time = Column(DateTime, nullable=True)
    gate = Column(String, nullable=True)
    qr_code = Column(String, nullable=True)  # QR code payload

    ticket = relationship("Ticket", back_populates="check_in")


class CancellationPolicy(Base):
    __tablename__ = "cancellation_policy"

    id = Column(Integer, primary_key=True)
    min_hours_before_departure = Column(Integer, default=24)
    allow_card_refund = Column(Boolean, default=True)
    allow_apple_pay_refund = Column(Boolean, default=True)
    refund_fee_percent = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)


class Refund(Base):
    __tablename__ = "refunds"

    id = Column(Integer, primary_key=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    booking = relationship("Booking")
    method = Column(String)  # CARD / APPLE_PAY
    card_last4 = Column(String, nullable=True)
    card_holder = Column(String, nullable=True)
    status = Column(String, default="PENDING")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="notifications")
