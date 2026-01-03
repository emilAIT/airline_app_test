"""Payment repository."""
from typing import Optional
from sqlalchemy.orm import Session
from app.models.payment import Payment


class PaymentRepository:
    """Data access layer for payments."""
    
    def create(
        self,
        db: Session,
        booking_id: int,
        idempotency_key: str,
        amount: float,
        payment_method: str,
        status: str
    ) -> Payment:
        """Create payment."""
        payment = Payment(
            booking_id=booking_id,
            idempotency_key=idempotency_key,
            amount=amount,
            payment_method=payment_method,
            status=status
        )
        db.add(payment)
        db.flush()
        db.refresh(payment)
        return payment
    
    def get_by_idempotency_key(self, db: Session, key: str) -> Optional[Payment]:
        """Get payment by idempotency key (for idempotency check)."""
        return db.query(Payment).filter(Payment.idempotency_key == key).first()
    
    def update_status(self, db: Session, payment: Payment, new_status: str):
        """Update payment status."""
        payment.status = new_status
        db.flush()
        db.refresh(payment)
        return payment


payment_repository = PaymentRepository()
