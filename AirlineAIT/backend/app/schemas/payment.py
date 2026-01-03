from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any
from app.models.payment import PaymentMethod, PaymentStatus


class PaymentCreate(BaseModel):
    booking_id: int
    method: PaymentMethod
    transaction_id: Optional[str] = None  # For idempotency


class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    amount: float
    method: str
    status: str
    transaction_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class PaymentDetailResponse(PaymentResponse):
    user_info: Dict[str, Any]
    booking_info: Dict[str, Any]
    flight_info: Dict[str, Any]

