from sqlalchemy import Column, Integer, String, Float, ForeignKey
from db.base import Base
import enum
from sqlalchemy.sql import func
from sqlalchemy import DateTime

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    method = Column(String)  # CARD, APPLE_PAY, GOOGLE_PAY
    status = Column(String)  # PENDING, PAID, FAILED
    amount = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"