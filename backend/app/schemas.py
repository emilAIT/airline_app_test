from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime, date
from .enums import (
    UserRole, BookingStatus, FlightStatus, PaymentStatus, 
    PaymentMethod, SeatCategory, AnnouncementType
)


# Auth Schemas
class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str
    id: int
    email: str
    role: UserRole


class UserResponse(BaseModel):
    id: int
    email: str
    role: UserRole
    
    class Config:
        from_attributes = True


# Passenger Profile Schemas
class PassengerProfileUpdate(BaseModel):
    full_name: str
    phone_number: str
    passport_number: str
    nationality: str
    date_of_birth: date


class PassengerProfileResponse(BaseModel):
    id: int
    user_id: int
    full_name: Optional[str]
    phone_number: Optional[str]
    passport_number: Optional[str]
    nationality: Optional[str]
    date_of_birth: Optional[datetime]
    is_complete: bool
    
    class Config:
        from_attributes = True


# Airport Schemas
class AirportResponse(BaseModel):
    id: int
    code: str
    name: str
    city: str
    country: str
    
    class Config:
        from_attributes = True


# Airplane Schemas
class SeatTemplateCreate(BaseModel):
    row_number: int
    seat_label: str
    category: SeatCategory = SeatCategory.STANDARD


class SeatTemplateResponse(BaseModel):
    id: int
    row_number: int
    seat_label: str
    category: SeatCategory
    
    class Config:
        from_attributes = True


class AirplaneCreate(BaseModel):
    model: str
    registration: Optional[str] = None
    manufacturer: Optional[str] = None
    seat_templates: Optional[List[SeatTemplateCreate]] = None
    total_seats: Optional[int] = None


class AirplaneUpdate(BaseModel):
    model: Optional[str] = None
    registration: Optional[str] = None
    manufacturer: Optional[str] = None
    total_seats: Optional[int] = None


class AirplaneResponse(BaseModel):
    id: int
    model: str
    registration: str
    total_seats: int
    
    class Config:
        from_attributes = True


class AirplaneDetailResponse(BaseModel):
    id: int
    model: str
    registration: str
    total_seats: int
    seat_template: List[SeatTemplateResponse]
    
    class Config:
        from_attributes = True


# Flight Schemas
class FlightCreate(BaseModel):
    flight_number: str
    airplane_id: int
    origin_airport_id: int
    destination_airport_id: int
    departure_time: datetime
    arrival_time: datetime
    base_price: float
    gate: Optional[str] = None
    terminal: Optional[str] = None
    boarding_time: Optional[datetime] = None


class FlightUpdate(BaseModel):
    departure_time: Optional[datetime] = None
    arrival_time: Optional[datetime] = None
    gate: Optional[str] = None
    terminal: Optional[str] = None
    status: Optional[FlightStatus] = None
    boarding_time: Optional[datetime] = None


class FlightSearchResponse(BaseModel):
    id: int
    flight_number: str
    departure_time: datetime
    arrival_time: datetime
    duration_minutes: int
    base_price: float
    available_seats: int
    status: FlightStatus
    origin_airport: AirportResponse
    destination_airport: AirportResponse
    
    class Config:
        from_attributes = True


class FlightDetailResponse(BaseModel):
    id: int
    flight_number: str
    airplane_id: int
    origin_airport_id: int
    destination_airport_id: int
    departure_time: datetime
    arrival_time: datetime
    duration_minutes: int
    base_price: float
    available_seats: int
    gate: Optional[str]
    terminal: Optional[str]
    status: FlightStatus
    boarding_time: Optional[datetime]
    origin_airport: AirportResponse
    destination_airport: AirportResponse
    airplane: AirplaneResponse
    
    class Config:
        from_attributes = True


# Seat Schemas
class SeatResponse(BaseModel):
    seat_number: str
    category: SeatCategory
    is_available: bool
    price: float


class SeatMapResponse(BaseModel):
    flight_id: int
    seats: List[SeatResponse]


# Booking Schemas
class PassengerInfo(BaseModel):
    full_name: str
    passport_number: str


class SeatSelection(BaseModel):
    passenger_name: str
    passport_number: str
    seat_number: Optional[str] = None  # If None, auto-assign


class BookingCreate(BaseModel):
    flight_id: int
    passengers: List[SeatSelection]


class BookingResponse(BaseModel):
    id: int
    pnr: str
    flight_id: int
    user_id: int
    status: BookingStatus
    total_price: float
    created_at: datetime
    
    class Config:
        from_attributes = True


class TicketResponse(BaseModel):
    id: int
    ticket_number: str
    booking_id: int
    passenger_name: str
    passport_number: str
    seat_number: str
    seat_category: SeatCategory
    price: float
    created_at: datetime
    
    class Config:
        from_attributes = True


class FlightSimpleResponse(BaseModel):
    id: int
    flight_number: str
    departure_time: datetime
    arrival_time: datetime
    duration_minutes: int
    origin_airport: AirportResponse
    destination_airport: AirportResponse
    status: FlightStatus
    terminal: Optional[str]
    gate: Optional[str]

    class Config:
        from_attributes = True

class BookingDetailResponse(BaseModel):
    id: int
    pnr: str
    flight_id: int
    user_id: int
    status: BookingStatus
    total_price: float
    created_at: datetime
    flight: FlightSimpleResponse
    tickets: List[TicketResponse]
    
    class Config:
        from_attributes = True


# Payment Schemas
class PaymentCreate(BaseModel):
    booking_id: int
    method: PaymentMethod
    idempotency_key: Optional[str] = None


class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    amount: float
    method: PaymentMethod
    status: PaymentStatus
    created_at: datetime
    paid_at: Optional[datetime]
    
    class Config:
        from_attributes = True


# Check-in Schemas
class CheckInCreate(BaseModel):
    ticket_id: int


class BoardingPassResponse(BaseModel):
    passenger_name: str
    flight_number: str
    seat_number: str
    gate: Optional[str]
    boarding_time: Optional[datetime]
    departure_time: datetime
    qr_code: str
    
    class Config:
        from_attributes = True


# Announcement Schemas
class AnnouncementCreate(BaseModel):
    flight_id: int
    type: AnnouncementType
    title: str
    message: str


class AnnouncementResponse(BaseModel):
    id: int
    flight_id: int
    type: AnnouncementType
    title: str
    message: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# Staff Booking Management
class SeatReassign(BaseModel):
    ticket_id: int
    new_seat_number: str

