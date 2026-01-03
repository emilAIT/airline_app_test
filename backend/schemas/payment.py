from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime
from app.models.payment import PaymentStatus, PaymentMethod


class PaymentCreate(BaseModel):
    payment_method: str  # Changed to str for flexibility
    idempotency_key: str
    
    @field_validator('payment_method')
    @classmethod
    def validate_payment_method(cls, v):
        # Convert string to PaymentMethod enum
        try:
            return PaymentMethod[v.upper()]
        except KeyError:
            # Try direct value match
            for method in PaymentMethod:
                if method.value == v.upper():
                    return method
            raise ValueError(f'Invalid payment method: {v}. Must be one of: CARD, APPLE_PAY, GOOGLE_PAY')
    
    class Config:
        use_enum_values = True


class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    amount: float
    payment_method: PaymentMethod
    status: PaymentStatus
    idempotency_key: str
    transaction_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
