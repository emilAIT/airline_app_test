"""
Payment model - payment transactions for bookings.
"""
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Payment(Base):
    """
    Payment transaction for a booking.
    
    Idempotency:
        Uses idempotency_key (UUID v4 from client) to ensure duplicate
        payment requests return the same result without double-charging.
    
    Status:
        - PENDING: payment initiated
        - SUCCESS: payment completed successfully
        - FAILED: payment declined/failed
    
    Business Rules:
        - idempotency_key must be unique (enforced by DB constraint)
        - On SUCCESS, booking status changes to CONFIRMED
        - Mock payment: randomly succeeds/fails for testing
    """
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign key to booking
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False, index=True)
    
    # Idempotency key from client (UUID v4)
    # CRITICAL: ensures idempotent payment processing
    idempotency_key = Column(String(100), unique=True, nullable=False, index=True)
    
    # Payment amount
    amount = Column(Numeric(10, 2), nullable=False)
    
    # Status: PENDING, SUCCESS, FAILED
    # Enforced at application level (Pydantic validation)
    status = Column(String(20), nullable=False, default="PENDING")
    
    # Payment method (e.g., "MOCK_CARD")
    payment_method = Column(String(50))
    
    # When payment was processed (SUCCESS or FAILED)
    processed_at = Column(DateTime(timezone=True))
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to booking
    booking = relationship("Booking", back_populates="payments")
    
    # Check constraints
    __table_args__ = (
        CheckConstraint('amount >= 0', name='check_amount_positive'),
    )
    
    def __repr__(self):
        return f"<Payment(id={self.id}, booking_id={self.booking_id}, status='{self.status}')>"
