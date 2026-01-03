from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_user
from app.models.all_models import User, Booking, UserRole, BookingStatus
from app.schemas.schemas import PaymentCreate, PaymentOut
from app.services.payment_service import process_mock_payment, create_payment_intent
from datetime import datetime, timezone

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/booking/{booking_id}/intent")
@router.post("/booking/{booking_id}/intent/")
def create_payment_intent_endpoint(
    booking_id: int,
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a Stripe Payment Intent for a booking"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403, detail="Only passengers can make payments")

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=403, detail="Not authorized to pay for this booking")

    try:
        intent_data = create_payment_intent(
            db,
            booking_id,
            payment_data.method
        )
        return intent_data
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# FUNCTION: process_payment
# PURPOSE: Processes mock payment for booking (CARD / APPLE_PAY / GOOGLE_PAY)
# ENDPOINT: POST /payments/booking/{booking_id} (accepts both with/without trailing slash)
# IMPORTANT: Dual route decorator prevents HTTP 307 redirects for Flutter
# CALLED BY: Flutter PaymentScreen
@router.post("/booking/{booking_id}", response_model=PaymentOut, status_code=status.HTTP_201_CREATED)
@router.post("/booking/{booking_id}/", response_model=PaymentOut, status_code=status.HTTP_201_CREATED)
def process_payment(
    booking_id: int,
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process payment for a booking (mock payment)"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403, detail="Only passengers can make payments")

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=403, detail="Not authorized to pay for this booking")
    
    # Check if booking is expired
    if booking.status == BookingStatus.EXPIRED:
        raise HTTPException(
            status_code=400, detail="Booking expired. Seats have been released.")
    
    # Check if hold timer has passed for CREATED bookings
    if booking.status == BookingStatus.CREATED:
        # Ensure aware datetime comparisons
        now = datetime.now(timezone.utc)
        booking_hold = booking.hold_until
        
        # If naive, make it aware (assume UTC as it's stored as UTC)
        if booking_hold and booking_hold.tzinfo is None:
            booking_hold = booking_hold.replace(tzinfo=timezone.utc)

        if booking_hold and booking_hold < now:
            booking.status = BookingStatus.EXPIRED
            db.commit()
            raise HTTPException(
                status_code=400, detail="Booking hold expired. Please create a new booking.")

    try:
        payment = process_mock_payment(
            db,
            booking_id,
            payment_data.method,
            card_number=payment_data.card_number,
            card_holder=payment_data.card_holder,
            expiry_month=payment_data.expiry_month,
            expiry_year=payment_data.expiry_year,
            cvv=payment_data.cvv,
            # Use transaction_id field for payment_intent_id
            payment_intent_id=payment_data.transaction_id
        )
        return payment
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
