from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import datetime
from .. import models, schemas
from ..enums import PaymentStatus, BookingStatus


def process_payment(db: Session, payment_data: schemas.PaymentCreate) -> models.Payment:
    # Check for idempotency
    if payment_data.idempotency_key:
        existing_payment = db.query(models.Payment).filter(
            models.Payment.idempotency_key == payment_data.idempotency_key
        ).first()
        if existing_payment:
            return existing_payment
    
    # Get booking
    booking = db.query(models.Booking).filter(models.Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    # Check if booking already has a payment
    existing_payment = db.query(models.Payment).filter(models.Payment.booking_id == booking.id).first()
    if existing_payment:
        if existing_payment.status == PaymentStatus.PAID:
            return existing_payment
        # Update existing payment instead of creating new one
        existing_payment.method = payment_data.method
        existing_payment.status = PaymentStatus.PAID
        existing_payment.paid_at = datetime.utcnow()
        if payment_data.idempotency_key:
            existing_payment.idempotency_key = payment_data.idempotency_key
        
        # Confirm booking
        booking.status = BookingStatus.CONFIRMED
        
        # Release temporary holds by setting them far in the future (they're now confirmed)
        db.query(models.SeatHold).filter(models.SeatHold.booking_id == booking.id).delete()
        
        db.commit()
        db.refresh(existing_payment)
        return existing_payment
    
    # Check if booking is in valid state
    if booking.status != BookingStatus.CREATED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Booking is in {booking.status} state, cannot process payment"
        )
    
    # Check if seat hold is still valid
    seat_holds = db.query(models.SeatHold).filter(models.SeatHold.booking_id == booking.id).all()
    if seat_holds and seat_holds[0].held_until < datetime.utcnow():
        # Holds expired, cancel booking
        booking.status = BookingStatus.CANCELLED
        db.query(models.SeatHold).filter(models.SeatHold.booking_id == booking.id).delete()
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Seat hold expired. Please create a new booking."
        )
    
    # Simulate payment (always succeeds in this mock)
    payment = models.Payment(
        booking_id=booking.id,
        amount=booking.total_price,
        method=payment_data.method,
        status=PaymentStatus.PAID,
        idempotency_key=payment_data.idempotency_key,
        paid_at=datetime.utcnow()
    )
    db.add(payment)
    
    # Confirm booking
    booking.status = BookingStatus.CONFIRMED
    
    # Remove seat holds (seats are now confirmed)
    db.query(models.SeatHold).filter(models.SeatHold.booking_id == booking.id).delete()
    
    db.commit()
    db.refresh(payment)
    
    return payment


def get_payment_by_booking(db: Session, booking_id: int) -> models.Payment:
    payment = db.query(models.Payment).filter(models.Payment.booking_id == booking_id).first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return payment

