"""
Payments API routes.

Endpoints:
- POST /: Process payment for a booking
- GET /my: Get user's payment history

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.api.deps import get_current_passenger
from typing import List
from app.models.user import User
from app.models.payment import Payment
from app.schemas.payment import PaymentCreate, PaymentResponse
from app.services.payment import process_payment

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
def process_payment_endpoint(
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Process payment for a booking"""
    # Verify booking belongs to user
    from app.models.booking import Booking
    booking = db.query(Booking).filter(Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to pay for this booking"
        )
    
    payment = process_payment(
        db,
        payment_data.booking_id,
        payment_data.method,
        payment_data.transaction_id
    )
    return payment

@router.get("/my", response_model=List[PaymentResponse])
def get_my_payments(
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get current user's payment history"""
    from app.models.booking import Booking
    payments = db.query(Payment).join(Booking).filter(Booking.user_id == current_user.id).all()
    return payments
