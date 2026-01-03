from pydantic import BaseModel, EmailStr
from typing import Optional, List

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: str
    is_active: bool
    role: str

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class Airport(BaseModel):
    code: str
    name: str
    city: str
    country: str

    class Config:
        from_attributes = True

class Flight(BaseModel):
    id: str
    flight_number: str
    origin_code: str
    destination_code: str
    departure_time: str
    arrival_time: str
    price: float
    # We could include nested Airport objects here if needed, keeping it flat for now as per minimal rule

    class Config:
        from_attributes = True

class PassengerBase(BaseModel):
    first_name: str
    last_name: str
    passport_number: str

class BookingCreate(BaseModel):
    flight_id: str
    passengers: List[PassengerBase]

class BookingResponse(BaseModel):
    pnr: str
    status: str
    total_price: float
    flight_id: str
    
    class Config:
        from_attributes = True

class PaymentRequest(BaseModel):
    booking_pnr: str
    amount: float
    currency: str
    card_number: str
    expiry_date: str
    cvv: str

class PaymentResponse(BaseModel):
    success: bool
    transaction_id: str
    message: str
