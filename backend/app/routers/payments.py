from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import schemas
from ..database import get_db
from ..services import payment_service, booking_service
from ..auth import get_current_passenger

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/", response_model=schemas.PaymentResponse, status_code=status.HTTP_201_CREATED)
def process_payment(
    payment_data: schemas.PaymentCreate,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Process payment for a booking (mock payment)"""
    # Verify booking belongs to user
    # Verify booking belongs to user
    from .. import models
    booking = db.query(models.Booking).filter(models.Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    return payment_service.process_payment(db, payment_data)


@router.get("/{booking_id}", response_model=schemas.PaymentResponse)
def get_payment(
    booking_id: int,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get payment details for a booking"""
    from .. import models
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    return payment_service.get_payment_by_booking(db, booking_id)

