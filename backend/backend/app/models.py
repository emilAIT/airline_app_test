import uuid 
from typing import Optional
from datetime import date, datetime 
from pydantic import EmailStr
from enum import Enum 
from sqlmodel import Field, Relationship, SQLModel


# =====================
# USER
# =====================

class UserRole(str, Enum):
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"


class UserBase(SQLModel):
    email: EmailStr = Field(index=True, max_length=255)
    is_active: bool = True
    full_name: str | None = Field(default=None, max_length=255)
    role: UserRole = Field(default=UserRole.PASSENGER)


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)


class UserRegister(SQLModel):
    email: EmailStr = Field(max_length=255)
    password: str = Field(min_length=8, max_length=128)

    full_name: str = Field(max_length=255)
    phone_number: str = Field(max_length=30)
    passport_number: str = Field(max_length=30)
    nationality: str = Field(max_length=80)
    date_of_birth: date
    role: UserRole = UserRole.PASSENGER


class UserUpdate(UserBase): 
    email: EmailStr | None = Field(default=None, max_length=255) 
    password: str | None = Field(default=None, min_length=8, max_length=128) 
    role: UserRole | None = None


class UserUpdateMe(SQLModel): 
    full_name: str | None = Field(default=None, max_length=255) 
    email: EmailStr | None = Field(default=None, max_length=255)


class UpdatePassword(SQLModel):
    current_password: str = Field(min_length=8, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class User(UserBase, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    hashed_password: str

    bookings: list["Booking"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"cascade": "all, delete"},
    )

    passenger_profile: Optional["PassengerProfile"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"}, 
        )

    # passenger_profile: "PassengerProfile | None" = Relationship(
    #     back_populates="user",
    #     sa_relationship_kwargs={"cascade": "all, delete-orphan"}, 
    #     )


class UserPublic(UserBase):
    id: str


class UsersPublic(SQLModel):
    data: list[UserPublic]
    count: int


# =====================
# PASSENGER PROFILE
# =====================

class PassengerProfileBase(SQLModel):
    phone_number: str = Field(max_length=30)
    passport_number: str = Field(index=True, max_length=30)
    nationality: str = Field(max_length=80)
    date_of_birth: date


class PassengerProfile(PassengerProfileBase, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    user_id: str = Field(foreign_key="user.id", index=True, unique=True)
    user: User = Relationship(back_populates="passenger_profile")


class PassengerProfileCreate(PassengerProfileBase):
    pass


class PassengerProfileUpdate(SQLModel): 
    phone_number: str | None = Field(default=None, max_length=30) 
    passport_number: str | None = Field(default=None, max_length=30) 
    nationality: str | None = Field(default=None, max_length=80) 
    date_of_birth: date | None = None


class PassengerProfilePublic(PassengerProfileBase):
    id: str
    user_id: str


# =====================
# AUTH
# =====================

class Message(SQLModel):
    message: str


class Token(SQLModel):
    access_token: str
    token_type: str = "bearer"


class TokenPayload(SQLModel):
    sub: str | None = None


class NewPassword(SQLModel):
    token: str
    new_password: str = Field(min_length=8, max_length=128)


# =====================
# AIRPORT
# =====================

class AirportBase(SQLModel):
    code: str = Field(min_length=3, max_length=3, index=True)
    name: str = Field(max_length=255)
    city: str = Field(max_length=255)
    country: str = Field(max_length=255)


class Airport(AirportBase, table=True):
    id: str = Field( default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True, )

    departures: list["Flight"] = Relationship(
        back_populates="origin_airport",
        sa_relationship_kwargs={"foreign_keys": "[Flight.origin_airport_id]"},
    )

    arrivals: list["Flight"] = Relationship(
        back_populates="destination_airport",
        sa_relationship_kwargs={"foreign_keys": "[Flight.destination_airport_id]"},
    )


class AirportPublic(AirportBase):
    id: str


class AirportsPublic(SQLModel):
    data: list[AirportPublic]
    count: int


class AirportCreate(AirportBase): 
    pass


class AirportUpdate(SQLModel):
    code: str | None = Field(default=None, min_length=3, max_length=3)
    name: str | None = Field(default=None, max_length=255)
    city: str | None = Field(default=None, max_length=255)
    country: str | None = Field(default=None, max_length=255)


# =====================
# AIRPLANE
# =====================

class AirplaneBase(SQLModel):
    model: str = Field(max_length=100)
    total_seats: int = Field(gt=0)


class Airplane(AirplaneBase, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True)

    seat_templates: list["SeatTemplate"] = Relationship(
        back_populates="airplane",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


class AirplaneUpdate(SQLModel): 
    model: str | None = Field(default=None, max_length=100)


class AirplanePublic(AirplaneBase): 
    id: str


class SeatCategory(str, Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"


class SeatTemplateBase(SQLModel):
    row: int = Field(gt=0)
    seat_label: str = Field(max_length=1)
    category: SeatCategory = Field(default=SeatCategory.STANDARD)


class SeatTemplate(SeatTemplateBase, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True)
    airplane_id: str = Field(foreign_key="airplane.id", index=True)
    airplane: Airplane = Relationship(back_populates="seat_templates")


class SeatTemplatePublic(SeatTemplateBase): 
    id: str


class AirplaneWithSeatsPublic(AirplaneBase): 
    id: str 
    seat_templates: list[SeatTemplatePublic]


class SeatTemplateCreate(SeatTemplateBase): 
    pass


class AirplaneCreate(SQLModel): 
    model: str 
    total_seats: int 
    seat_templates: list[SeatTemplateCreate]


# =====================
# FLIGHT
# =====================

class FlightStatus(str, Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class FlightBase(SQLModel):
    flight_number: str = Field(max_length=10, index=True)
    origin_airport_id: str = Field(foreign_key="airport.id", index=True)
    destination_airport_id: str = Field(foreign_key="airport.id")
    departure_time: datetime
    arrival_time: datetime
    status: FlightStatus = Field(default=FlightStatus.SCHEDULED)
    gate: str | None = Field(default=None, max_length=10) 
    terminal: str | None = Field(default=None, max_length=10)


class Flight(FlightBase, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True)

    airplane_id: str | None = Field(foreign_key="airplane.id")
    airplane: Optional["Airplane"] = Relationship()

    origin_airport: "Airport" = Relationship(
        back_populates="departures",
        sa_relationship_kwargs={"foreign_keys": "[Flight.origin_airport_id]"},
    )

    destination_airport: "Airport" = Relationship(
        back_populates="arrivals",
        sa_relationship_kwargs={"foreign_keys": "[Flight.destination_airport_id]"},
    )

    seats: list["FlightSeat"] = Relationship(
        back_populates="flight",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )

    bookings: list["Booking"] = Relationship(back_populates="flight")


class FlightCreate(FlightBase): 
    airplane_id: str | None = None


class FlightPublic(FlightBase): 
    id: str 
    airplane_id: str | None
    origin_airport_code: str | None = None
    destination_airport_code: str | None = None


class FlightsPublic(SQLModel): 
    data: list[FlightPublic] 
    count: int


class FlightUpdate(SQLModel): 
    departure_time: datetime | None = None 
    arrival_time: datetime | None = None 
    status: FlightStatus | None = None 
    gate: str | None = Field(default=None, max_length=10) 
    terminal: str | None = Field(default=None, max_length=10) 
    airplane_id: str | None = None


class FlightStatusUpdate(SQLModel): 
    status: FlightStatus


class FlightGateTerminalUpdate(SQLModel): 
    gate: str | None = Field(default=None, max_length=10) 
    terminal: str | None = Field(default=None, max_length=10)


# =====================
# FLIGHT SEAT
# =====================

class FlightSeatStatus(str, Enum): 
    AVAILABLE = "AVAILABLE" 
    BOOKED = "BOOKED" 
    BLOCKED = "BLOCKED"


class FlightSeatBase(SQLModel): 
    row: int 
    seat_label: str 
    category: SeatCategory 
    price: int = Field(gt=0) 
    status: FlightSeatStatus = Field(default=FlightSeatStatus.AVAILABLE)


class FlightSeat(FlightSeatBase, table=True): 
    __tablename__ = "flight_seat" 
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True,
        )
    flight_id: str = Field(foreign_key="flight.id", index=True) 
    flight: "Flight" = Relationship(back_populates="seats")


class FlightSearchResult(SQLModel): 
    flight_id: str 
    flight_number: str 
    origin_airport_code: str
    destination_airport_code: str
    departure_time: datetime 
    arrival_time: datetime 
    duration_minutes: int 
    price_from: int 
    available_seats: int 
    status: FlightStatus


# =====================
# SEAT HOLD
# =====================

class SeatHold(SQLModel, table=True): 
    __tablename__ = "seat_hold"

    id: str = Field( default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True, )

    flight_id: str = Field(foreign_key="flight.id", index=True) 
    flight_seat_id: str = Field(foreign_key="flight_seat.id", index=True)

    expires_at: datetime = Field(index=True)

    flight: "Flight" = Relationship() 
    flight_seat: "FlightSeat" = Relationship()


class SeatHoldCreate(SQLModel): 
    flight_id: str 
    flight_seat_id: str


class SeatHoldPublic(SQLModel): 
    id: str 
    flight_id: str 
    flight_seat_id: str 
    expires_at: datetime


class SeatHoldsPublic(SQLModel): 
    data: list[SeatHoldPublic] 
    count: int

# =====================
# BOOKING
# =====================

class BookingStatus(str, Enum):
    CREATED = "CREATED"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class BookingPassenger(SQLModel): 
    passenger_name: str = Field(max_length=255) 
    seat_id: str | None = None


class BookingBase(SQLModel):
    status: BookingStatus = Field(default=BookingStatus.CREATED)


class Booking(BookingBase, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()),
                    primary_key=True, index=True)

    pnr: str = Field(max_length=10, unique=True, index=True)

    user_id: str = Field(foreign_key="user.id", index=True)
    flight_id: str = Field(foreign_key="flight.id", index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    user: "User" = Relationship(back_populates="bookings")
    flight: "Flight" = Relationship(back_populates="bookings")

    seats: list["BookingSeat"] = Relationship(
        back_populates="booking",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )

    tickets: list["Ticket"] = Relationship(
        back_populates="booking",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )



# # =====================
# # RELATIONSHIPS
# # =====================

# user: "User" = Relationship(back_populates="bookings")

# seats: list["BookingSeat"] = Relationship( back_populates="booking", sa_relationship_kwargs={"cascade": "all, delete-orphan"}, )


# =====================
# BOOKING SEAT
# =====================

class BookingSeat(SQLModel, table=True): 
    id: str = Field( default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True, )

    booking_id: str = Field(foreign_key="booking.id", index=True) 
    flight_seat_id: str = Field(foreign_key="flight_seat.id", index=True)

    booking: "Booking" = Relationship(back_populates="seats") 
    flight_seat: "FlightSeat" = Relationship()


class BookingCreate(SQLModel): 
    flight_id: str 
    passengers: list[BookingPassenger]


class BookingPublic(SQLModel): 
    id: str 
    pnr: str 
    status: BookingStatus 
    flight_id: str 
    created_at: datetime


class BookingsPublic(SQLModel): 
    data: list[BookingPublic] 
    count: int


# =====================
# TICKETING
# =====================

class TicketBase(SQLModel):
    passenger_name: str = Field(max_length=255)
    seat_number: str = Field(max_length=5)   # например "12A"


class Ticket(TicketBase, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()),
                    primary_key=True, index=True)

    ticket_number: str = Field(
        max_length=20,
        index=True,
        unique=True,
        description="Unique ticket number",
    )

    booking_id: str = Field(foreign_key="booking.id", index=True)
    flight_seat_id: str | None = Field(foreign_key="flight_seat.id", index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    booking: "Booking" = Relationship(back_populates="tickets")
    flight_seat: Optional["FlightSeat"] = Relationship()
    checkin: Optional["CheckIn"] = Relationship(back_populates="ticket")


class TicketCreate(TicketBase):
    flight_seat_id: str | None = None


class TicketPublic(TicketBase):
    id: str
    ticket_number: str
    booking_id: str
    flight_seat_id: str | None
    created_at: datetime


class TicketsPublic(SQLModel):
    data: list[TicketPublic]
    count: int


# =====================
# PAYMENT
# =====================

class PaymentMethod(str, Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class PaymentStatus(str, Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


class PaymentBase(SQLModel):
    method: PaymentMethod
    status: PaymentStatus = Field(default=PaymentStatus.PENDING)


class Payment(PaymentBase, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    booking_id: str = Field(foreign_key="booking.id", index=True)

    idempotency_key: str = Field(
        max_length=100,
        index=True,
        unique=True,
    )

    created_at: datetime = Field(default_factory=datetime.utcnow)

    booking: "Booking" = Relationship()


class PaymentCreate(SQLModel):
    booking_id: str
    method: PaymentMethod
    idempotency_key: str = Field(max_length=64)


class PaymentPublic(PaymentBase):
    id: str
    booking_id: str
    idempotency_key: str
    created_at: datetime


class PaymentsPublic(SQLModel):
    data: list[PaymentPublic]
    count: int


# =====================
# CHECK-IN
# =====================

class CheckIn(SQLModel, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    # 1 ticket -> 1 check-in
    ticket_id: str = Field(
        foreign_key="ticket.id",
        index=True,
        unique=True,
    )

    checked_in_at: datetime = Field(
        default_factory=datetime.utcnow
    )

    # relationships
    ticket: "Ticket" = Relationship(back_populates="checkin")
    boarding_pass: Optional["BoardingPass"] = Relationship(
        back_populates="checkin",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


class BoardingPass(SQLModel, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    checkin_id: str = Field(
        foreign_key="checkin.id",
        unique=True,
        index=True,
    )

    seat_number: str = Field(
        max_length=5,
        description="Seat number like 12A",
    )

    gate: str | None = Field(
        default=None,
        max_length=10,
    )

    boarding_group: str | None = Field(
        default=None,
        max_length=5,
    )

    qr_code: str = Field(
        description="Mock QR payload for boarding",
    )

    created_at: datetime = Field(
        default_factory=datetime.utcnow
    )

    checkin: "CheckIn" = Relationship(back_populates="boarding_pass")


class CheckInCreate(SQLModel):
    ticket_id: str


class CheckInPublic(SQLModel):
    id: str
    ticket_id: str
    checked_in_at: datetime


class CheckInsPublic(SQLModel):
    data: list[CheckInPublic]
    count: int


class BoardingPassPublic(SQLModel):
    id: str
    checkin_id: str
    seat_number: str
    gate: str | None
    boarding_group: str | None
    qr_code: str
    created_at: datetime

# =====================
# ANNOUNCEMENT
# =====================

class AnnouncementType(str, Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING_STARTED = "BOARDING_STARTED"
    GENERAL = "GENERAL"


class AnnouncementBase(SQLModel):
    type: AnnouncementType
    title: str = Field(max_length=120)
    message: str = Field(max_length=2000)


class Announcement(AnnouncementBase, table=True):
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    flight_id: str = Field(foreign_key="flight.id", index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    # опционально, но полезно: кто (staff) создал
    created_by_user_id: str | None = Field(default=None, foreign_key="user.id", index=True)

    # relationships (если у тебя так принято)
    flight: "Flight" = Relationship()
    created_by: "User" = Relationship()


class AnnouncementCreate(AnnouncementBase):
    flight_id: str


class AnnouncementUpdate(SQLModel):
    type: AnnouncementType | None = None
    title: str | None = Field(default=None, max_length=120)
    message: str | None = Field(default=None, max_length=2000)


class AnnouncementPublic(AnnouncementBase):
    id: str
    flight_id: str
    created_at: datetime
    created_by_user_id: str | None


class AnnouncementsPublic(SQLModel):
    data: list[AnnouncementPublic]
    count: int
