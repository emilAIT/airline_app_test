"""
Payment model with method and status tracking.

Stores payment transactions with method (CARD, APPLE_PAY, GOOGLE_PAY)
and status (PENDING, PAID, FAILED). Links to bookings.

Part of: Backend Models
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum
from app.db.base import Base


class PaymentMethod(str, enum.Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    amount = Column(Float, nullable=False)
    method = Column(Enum(PaymentMethod), nullable=False)
    status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False)
    transaction_id = Column(String, unique=True, nullable=False, index=True)
    created_at = Column(DateTime, nullable=False)
    
    # Relationships
    booking = relationship("Booking", back_populates="payments")

