"""Payments API routes."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.booking import PaymentRequest, PaymentResponse
from app.services.payment_service import payment_service

router = APIRouter()


@router.post("/process", response_model=PaymentResponse)
def process_payment(
    data: PaymentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Process payment for booking (IDEMPOTENT).
    
    - Requires idempotency_key (UUID v4 from client)
    - Duplicate requests with same key return cached result
    - Mock payment: always succeeds for testing
    - On success: booking status → CONFIRMED, seats permanently held
    
    This endpoint is idempotent - safe to retry.
    """
    result = payment_service.process_payment(
        db=db,
        booking_pnr=data.booking_pnr,
        idempotency_key=data.idempotency_key,
        payment_method=data.payment_method
    )
    
    payment = result["payment"]
    booking = result["booking"]
    
    return PaymentResponse(
        payment_id=payment.id,
        booking_pnr=booking.pnr,
        amount=payment.amount,
        status=payment.status,
        booking_status=booking.status
    )


@router.post("/pay", response_model=PaymentResponse)
def pay(
    data: PaymentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Alias for /process (exam wording sometimes uses /payments/pay)."""
    return process_payment(data=data, current_user=current_user, db=db)
