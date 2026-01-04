from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime
from enum import Enum

# ENUMS
class UserRole(str, Enum):
    PASSENGER = "passenger"
    STAFF = "staff"
    ADMIN = "admin"

class UserStatus(str, Enum):
    PENDING_APPROVAL = "pending_approval"
    ACTIVE = "active"
    REJECTED = "rejected"
    DEACTIVATED = "deactivated"

class FlightStatus(str, Enum):
    SCHEDULED = "scheduled"
    BOARDING = "boarding"
    DELAYED = "delayed"
    CANCELLED = "cancelled"
    DEPARTED = "departed"
    LANDED = "landed"
    FINISHED = "finished"

class BookingStatus(str, Enum):
    PENDING = "pending"
    PAID = "paid"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"
    CHECKED_IN = "checked_in"

class SeatClass(str, Enum):
    ECONOMY = "economy"
    PREMIUM_ECONOMY = "premium_economy"
    BUSINESS = "business"
    FIRST = "first"

# MODELS
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    hashed_password: str
    role: UserRole = Field(default=UserRole.PASSENGER)
    status: UserStatus = Field(default=UserStatus.ACTIVE)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now())
    
    # Profile fields that all users have
    first_name: Optional[str] = Field(default=None)
    last_name: Optional[str] = Field(default=None)
    phone: Optional[str] = Field(default=None)
    
    # Relationships
    passenger_profile: Optional["PassengerProfile"] = Relationship(back_populates="user")
    staff_profile: Optional["StaffProfile"] = Relationship(back_populates="user")
    bookings: List["Booking"] = Relationship(back_populates="user")
    tickets: List["Ticket"] = Relationship(back_populates="passenger")
    owned_airplanes: List["Airplane"] = Relationship(back_populates="owner")
    created_announcements: List["Announcement"] = Relationship(back_populates="author")

class PassengerProfile(SQLModel, table=True):
    """Extended profile information for passengers"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", unique=True)
    date_of_birth: Optional[datetime] = Field(default=None)
    gender: Optional[str] = Field(default=None)
    passport_number: Optional[str] = Field(default=None, unique=True)
    nationality: Optional[str] = Field(default=None)
    address: Optional[str] = Field(default=None)
    emergency_contact: Optional[str] = Field(default=None)
    
    user: User = Relationship(back_populates="passenger_profile")

class StaffProfile(SQLModel, table=True):
    """Extended profile information for staff members"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", unique=True)
    employee_id: Optional[str] = Field(default=None, unique=True)
    department: Optional[str] = Field(default=None)
    position: Optional[str] = Field(default=None)
    hire_date: Optional[datetime] = Field(default=None)
    
    user: User = Relationship(back_populates="staff_profile")

class Airport(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(unique=True, index=True)
    name: str
    city: str
    country: str
    timezone: str
    
    departing_flights: List["Flight"] = Relationship(
        sa_relationship_kwargs={
            "primaryjoin": "Airport.id==Flight.departure_airport_id",
            "foreign_keys": "Flight.departure_airport_id"
        },
        back_populates="departure_airport"
    )
    arriving_flights: List["Flight"] = Relationship(
        sa_relationship_kwargs={
            "primaryjoin": "Airport.id==Flight.arrival_airport_id",
            "foreign_keys": "Flight.arrival_airport_id"
        },
        back_populates="arrival_airport"
    )

class Airplane(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    model: str
    registration: str = Field(unique=True)
    manufacturer: str
    total_seats: int
    economy_seats: int
    business_seats: int = Field(default=0)
    first_class_seats: int = Field(default=0)
    rows_count: int
    seats_per_row: int
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id")
    owner: Optional[User] = Relationship(back_populates="owned_airplanes")
    seat_templates: List["SeatTemplate"] = Relationship(back_populates="airplane")
    flights: List["Flight"] = Relationship(back_populates="airplane")

class SeatTemplate(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    airplane_id: int = Field(foreign_key="airplane.id")
    row_number: int
    seat_letter: str 
    seat_class: SeatClass = Field(default=SeatClass.ECONOMY)
    airplane: Airplane = Relationship(back_populates="seat_templates")
    tickets: List["Ticket"] = Relationship(back_populates="seat")

class Flight(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    flight_number: str = Field(index=True)
    departure_airport_id: int = Field(foreign_key="airport.id")
    arrival_airport_id: int = Field(foreign_key="airport.id")
    # Обязательный gate вылета, отображается пассажирам и в проверке
    gate_departure: str = Field(index=True)
    # Обязательный gate прилета, отображается пассажирам и в проверке
    gate_arrival: str = Field(index=True)
    scheduled_departure: datetime
    scheduled_arrival: datetime
    status: FlightStatus = Field(default=FlightStatus.SCHEDULED)
    airplane_id: int = Field(foreign_key="airplane.id")
    base_price: float
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id")
    check_in_opens: datetime
    check_in_closes: datetime
    
    departure_airport: Airport = Relationship(
        sa_relationship_kwargs={
            "primaryjoin": "Flight.departure_airport_id==Airport.id",
            "foreign_keys": "Flight.departure_airport_id"
        },
        back_populates="departing_flights"
    )
    arrival_airport: Airport = Relationship(
        sa_relationship_kwargs={
            "primaryjoin": "Flight.arrival_airport_id==Airport.id",
            "foreign_keys": "Flight.arrival_airport_id"
        },
        back_populates="arriving_flights"
    )
    airplane: Airplane = Relationship(back_populates="flights")
    bookings: List["Booking"] = Relationship(back_populates="flight")
    announcements: List["Announcement"] = Relationship(back_populates="flight")

class Booking(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    flight_id: int = Field(foreign_key="flight.id")
    booking_reference: str = Field(unique=True)
    status: BookingStatus = Field(default=BookingStatus.PENDING)
    total_price: float
    passengers_count: int = Field(default=1)
    created_at: datetime = Field(default_factory=lambda: datetime.now())
    user: User = Relationship(back_populates="bookings")
    flight: Flight = Relationship(back_populates="bookings")
    tickets: List["Ticket"] = Relationship(back_populates="booking")

class Ticket(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    booking_id: int = Field(foreign_key="booking.id")
    passenger_id: int = Field(foreign_key="user.id")
    seat_id: Optional[int] = Field(default=None, foreign_key="seattemplate.id")
    # Имя пассажира для групповой покупки (привязан к владельцу)
    passenger_first_name: Optional[str] = Field(default=None)
    # Фамилия пассажира для групповой покупки (привязан к владельцу)
    passenger_last_name: Optional[str] = Field(default=None)
    # Телефон пассажира
    passenger_phone: Optional[str] = Field(default=None)
    # ID паспорта пассажира
    passenger_passport_number: Optional[str] = Field(default=None)
    # Гражданство пассажира
    passenger_nationality: Optional[str] = Field(default=None)
    ticket_number: str = Field(unique=True)
    booking: Booking = Relationship(back_populates="tickets")
    passenger: User = Relationship() # Generic link to User
    seat: Optional[SeatTemplate] = Relationship(back_populates="tickets")

class Announcement(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    flight_id: int = Field(foreign_key="flight.id")
    author_id: int = Field(foreign_key="user.id")
    title: str
    content: str
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now())
    flight: Flight = Relationship(back_populates="announcements")
    author: User = Relationship(back_populates="created_announcements")

# Notification Types
class NotificationType(str, Enum):
    BOOKING_CREATED = "booking_created"
    BOOKING_PAID = "booking_paid"
    BOOKING_EXPIRED = "booking_expired"
    BOOKING_CANCELLED = "booking_cancelled"
    FLIGHT_UPDATE = "flight_update"
    FLIGHT_DELAYED = "flight_delayed"
    FLIGHT_CANCELLED = "flight_cancelled"
    STAFF_ANNOUNCEMENT = "staff_announcement"

class Notification(SQLModel, table=True):
    """User notifications for booking and flight events"""
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    notification_type: NotificationType
    title: str
    message: str
    is_read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=lambda: datetime.now())
    
    # Optional references
    booking_id: Optional[int] = Field(default=None, foreign_key="booking.id")
    flight_id: Optional[int] = Field(default=None, foreign_key="flight.id")


# SCHEMAS for API Responses (to ensure nested data is serialized)
class AirportRead(SQLModel):
    id: int
    code: str
    name: str
    city: str
    country: str
    timezone: str

class AirplaneRead(SQLModel):
    id: int
    model: str
    registration: str
    manufacturer: str
    total_seats: int
    economy_seats: int

class FlightRead(SQLModel):
    id: int
    flight_number: str
    departure_airport_id: int
    arrival_airport_id: int
    scheduled_departure: datetime
    scheduled_arrival: datetime
    status: FlightStatus
    airplane_id: int
    base_price: float
    owner_id: Optional[int]
    check_in_opens: datetime
    check_in_closes: datetime
    
    departure_airport: Optional[AirportRead] = None
    arrival_airport: Optional[AirportRead] = None
    airplane: Optional[AirplaneRead] = None

class TicketRead(SQLModel):
    id: int
    booking_id: int
    passenger_id: int
    seat_id: Optional[int]
    ticket_number: str

class BookingRead(SQLModel):
    id: int
    user_id: int
    flight_id: int
    booking_reference: str
    status: BookingStatus
    total_price: float
    passengers_count: int
    created_at: datetime
    
    flight: Optional[FlightRead] = None
    tickets: List[TicketRead] = []
