from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import datetime
import random
from app.models.booking import Booking, BookingStatus
from app.models.payment import Payment, PaymentStatus, PaymentMethod
from app.models.seat_hold import SeatHold


def process_payment(
    db: Session,
    booking_id: int,
    payment_method: PaymentMethod,
    idempotency_key: str
) -> Payment:
    """
    Process payment for a booking.
    Idempotent - per instructions.txt line 193.
    Mock payment - per instructions.txt lines 185-194.
    """
    # Check for existing payment with same idempotency_key
    existing_payment = db.query(Payment).filter(
        Payment.idempotency_key == idempotency_key
    ).first()
    
    if existing_payment:
        # Return existing payment (idempotent)
        return existing_payment
    
    # Get booking
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check if booking already has a payment
    if booking.payment:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Booking already has a payment"
        )
    
    # Check if booking is still in CREATED status
    if booking.status != BookingStatus.CREATED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot pay for booking with status {booking.status}"
        )
    
    # Check if hold has expired
    now = datetime.utcnow()
    if booking.held_until and booking.held_until < now:
        # Release seats and cancel booking
        db.query(SeatHold).filter(SeatHold.booking_id == booking_id).delete()
        booking.status = BookingStatus.CANCELLED
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Seat hold has expired. Please create a new booking."
        )
    
    # Calculate amount (sum of ticket prices based on flight price)
    amount = booking.flight.price * len(booking.tickets)
    
    # Mock payment processing
    # For testing: always succeed, or randomly succeed/fail
    payment_successful = True  # Always succeed for now
    # payment_successful = random.random() > 0.1  # 90% success rate
    
    # Generate transaction ID
    transaction_id = f"TXN-{datetime.utcnow().timestamp()}-{random.randint(1000, 9999)}"
    
    # Create payment record
    payment = Payment(
        booking_id=booking_id,
        amount=amount,
        payment_method=payment_method,
        status=PaymentStatus.PAID if payment_successful else PaymentStatus.FAILED,
        idempotency_key=idempotency_key,
        transaction_id=transaction_id
    )
    db.add(payment)
    
    if payment_successful:
        # Confirm booking and convert seat holds to permanent
        booking.status = BookingStatus.CONFIRMED
        
        # Delete seat holds (seats are now permanently booked via tickets)
        # We keep the constraint that confirmed bookings have tickets
        db.query(SeatHold).filter(SeatHold.booking_id == booking_id).delete()
    else:
        # Release seats and cancel booking
        db.query(SeatHold).filter(SeatHold.booking_id == booking_id).delete()
        booking.status = BookingStatus.CANCELLED
    
    db.commit()
    db.refresh(payment)
    
    if not payment_successful:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Payment failed. Please try again."
        )
    
    return payment


def get_payment(db: Session, booking_id: int) -> Payment:
    """Get payment for a booking"""
    payment = db.query(Payment).filter(Payment.booking_id == booking_id).first()
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    return payment
