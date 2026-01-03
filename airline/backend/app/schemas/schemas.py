from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime, date
from app.models.all_models import (
    UserRole, BookingStatus, PaymentMethod, PaymentStatus,
    UserRole, BookingStatus, PaymentMethod, PaymentStatus,
    FlightStatus, AnnouncementType, SeatCategory, AnnouncementPriority
)

# --- AUTH ---


class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None


class UserCreate(UserBase):
    password: str
    role: UserRole = UserRole.PASSENGER


class UserOut(UserBase):
    id: int
    role: UserRole

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str

# --- PASSENGER PROFILE ---


class PassengerProfileBase(BaseModel):
    passport_number: str
    phone_number: str
    nationality: str
    date_of_birth: date


class PassengerProfileCreate(PassengerProfileBase):
    pass


class PassengerProfileUpdate(BaseModel):
    passport_number: Optional[str] = None
    phone_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[date] = None


class PassengerProfileOut(PassengerProfileBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# --- AIRPORTS ---


class AirportOut(BaseModel):
    id: int
    code: str
    name: str
    city: str
    country: str
    image_url: Optional[str] = None # Added field

    class Config:
        from_attributes = True


class AirportCreate(BaseModel):
    code: str = Field(..., max_length=3)
    name: str
    city: str
    country: str
    image_url: Optional[str] = None # Added field

# --- AIRPLANES ---


class SeatConfig(BaseModel):
    rows: int
    seats_per_row: List[int]  # e.g., [3, 3] for 3-3 configuration
    extra_legroom_rows: Optional[List[int]] = []


class AirplaneOut(BaseModel):
    id: int
    model: str
    total_seats: int
    seat_config: Optional[str] = None

    class Config:
        from_attributes = True


class AirplaneCreate(BaseModel):
    model: str
    total_seats: int
    seat_config: SeatConfig

# --- FLIGHTS ---


class FlightOut(BaseModel):
    id: int
    flight_number: str
    origin: AirportOut
    destination: AirportOut
    airplane: Optional[AirplaneOut] = None
    departure_time: datetime
    arrival_time: datetime
    base_price: float
    status: FlightStatus
    gate: Optional[str] = None
    terminal: Optional[str] = None
    available_seats: Optional[int] = None  # Calculated field

    class Config:
        from_attributes = True


class FlightSearch(BaseModel):
    origin_id: Optional[int] = None
    destination_id: Optional[int] = None
    departure_date: Optional[date] = None


class FlightCreate(BaseModel):
    flight_number: str
    origin_id: int
    destination_id: int
    airplane_id: int
    departure_time: datetime
    arrival_time: datetime
    base_price: float
    gate: Optional[str] = None
    terminal: Optional[str] = None


class FlightUpdate(BaseModel):
    departure_time: Optional[datetime] = None
    arrival_time: Optional[datetime] = None
    status: Optional[FlightStatus] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None

# --- SEATS ---


class SeatOut(BaseModel):
    id: int
    seat_number: str
    category: SeatCategory
    is_available: bool
    row: Optional[int] = None
    column: Optional[str] = None

    class Config:
        from_attributes = True


class SeatMapResponse(BaseModel):
    flight_id: int
    seats: List[SeatOut]
    available_count: int
    total_count: int

# --- BOOKING & TICKETS ---


class TicketCreate(BaseModel):
    passenger_name: str
    seat_number: Optional[str] = None  # None for auto-assign


class TicketOut(BaseModel):
    id: int
    seat_number: str
    passenger_name: str
    ticket_number: str

    class Config:
        from_attributes = True


class BookingCreate(BaseModel):
    flight_id: int
    tickets: List[TicketCreate]


class BookingOut(BaseModel):
    id: int
    pnr: str
    status: BookingStatus
    created_at: datetime
    flight: FlightOut
    tickets: List[TicketOut]

    class Config:
        from_attributes = True


class BookingDetailOut(BookingOut):
    payment: Optional['PaymentOut'] = None

    class Config:
        from_attributes = True

# --- PAYMENT ---


class PaymentCreate(BaseModel):
    method: PaymentMethod
    transaction_id: Optional[str] = None
    # Payment details (optional, for card payments)
    card_number: Optional[str] = None
    card_holder: Optional[str] = None
    expiry_month: Optional[int] = None
    expiry_year: Optional[int] = None
    cvv: Optional[str] = None


class PaymentOut(BaseModel):
    id: int
    amount: float
    currency: str
    method: PaymentMethod
    status: PaymentStatus
    transaction_id: str

    class Config:
        from_attributes = True

# --- CHECK-IN ---


class CheckInCreate(BaseModel):
    ticket_id: int


class CheckInOut(BaseModel):
    id: int
    checked_in_at: datetime
    boarding_time: Optional[datetime] = None
    gate: Optional[str] = None
    qr_code: Optional[str] = None
    ticket: TicketOut

    class Config:
        from_attributes = True


class BoardingPassOut(BaseModel):
    passenger_name: str
    flight_number: str
    seat: str
    gate: Optional[str] = None
    boarding_time: Optional[datetime] = None
    qr_code: Optional[str] = None

# --- ANNOUNCEMENTS ---


class AnnouncementCreate(BaseModel):
    title: str
    message: str
    type: AnnouncementType
    priority: AnnouncementPriority
    flight_id: Optional[int] = None
    effective_from: Optional[datetime] = None
    expires_at: Optional[datetime] = None


# --- Cancellation Schemas ---

class CancellationInfo(BaseModel):
    allowed: bool
    description: str
    refund_amount: float

class RefundRequest(BaseModel):
    method: str  # CARD or APPLE_PAY
    refund_card_number: Optional[str] = None
    expiry_month: Optional[int] = None
    expiry_year: Optional[int] = None
    card_holder: Optional[str] = None
    cvv: Optional[str] = None

class RefundResponse(BaseModel):
    status: str
    refund_amount: float
    message: str

class CancellationPolicyCreate(BaseModel):
    min_hours_before_departure: int
    allow_card_refund: bool
    allow_apple_pay_refund: bool
    refund_fee_percent: int
    is_active: bool

class CancellationPolicyOut(CancellationPolicyCreate):
    id: int
    class Config:
        from_attributes = True


class AnnouncementOut(BaseModel):
    id: int
    flight_id: Optional[int] = None
    type: AnnouncementType
    priority: AnnouncementPriority
    title: str
    message: str
    created_at: datetime
    effective_from: datetime
    expires_at: Optional[datetime] = None
    flight: Optional[FlightOut] = None

    class Config:
        from_attributes = True

# --- SEAT HOLD ---


class SeatHoldOut(BaseModel):
    id: int
    seat_number: str
    held_until: datetime
    created_at: datetime

    class Config:
        from_attributes = True


# --- PHOTOS ---


class PhotoBase(BaseModel):
    category: str
    entity_type: Optional[str] = None
    entity_id: Optional[int] = None
    display_order: int = 0


class PhotoOut(PhotoBase):
    id: int
    url: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationOut(BaseModel):
    id: int
    user_id: int
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
