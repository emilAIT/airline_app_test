from sqlalchemy.orm import Session
from datetime import datetime
from zoneinfo import ZoneInfo
import random
import string
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.booking import Booking, BookingStatus
from fastapi import HTTPException, status


def generate_transaction_id() -> str:
    """Generate unique transaction ID"""
    return f"TXN{''.join(random.choices(string.ascii_uppercase + string.digits, k=15))}"


def process_payment(
    db: Session,
    booking_id: int,
    method: PaymentMethod,
    transaction_id: str = None
) -> Payment:
    """Process mock payment (idempotent)"""
    # Check if payment already exists with this transaction_id
    if transaction_id:
        existing_payment = db.query(Payment).filter(
            Payment.transaction_id == transaction_id
        ).first()
        if existing_payment:
            return existing_payment
    
    # Get booking
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check if already paid
    existing_paid = db.query(Payment).filter(
        Payment.booking_id == booking_id,
        Payment.status == PaymentStatus.PAID
    ).first()
    
    if existing_paid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Booking already paid"
        )
    
    # Check if booking is in HOLD status
    if booking.status != BookingStatus.HOLD:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot pay for booking in {booking.status.value} status"
        )
    
    # Calculate amount (sum of flight price for all tickets)
    from app.models.flight import Flight, FlightStatus
    from app.api.routes.staff import update_flight_status_based_on_time
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    
    # Ensure status is up to date
    update_flight_status_based_on_time(flight, db)
    
    # Block if departed, landed, boarding or cancelled
    if flight.status in [FlightStatus.CANCELLED, FlightStatus.DEPARTED, FlightStatus.LANDED, FlightStatus.BOARDING]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot pay for flight in {flight.status.value} status"
        )
    
    # Payment is allowed as long as the booking is in HOLD status and hold has not expired.
    # The HOLD status is managed by the 3-minute timer and the 30-minute booking cutoff.
    # We still block if the flight has reached BOARDING, DEPARTED, or LANDED status.
    if flight.status in [FlightStatus.BOARDING, FlightStatus.DEPARTED, FlightStatus.LANDED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Payment window closed. Flight is already {flight.status.value.lower()}."
        )

    amount = flight.price * len(booking.tickets)
    
    # Generate transaction ID if not provided
    if not transaction_id:
        transaction_id = generate_transaction_id()
        # Ensure uniqueness
        while db.query(Payment).filter(Payment.transaction_id == transaction_id).first():
            transaction_id = generate_transaction_id()
    
    # Mock payment processing (100% success rate for test environment)
    payment_success = True
    
    payment = Payment(
        booking_id=booking_id,
        amount=amount,
        method=method,
        status=PaymentStatus.PAID if payment_success else PaymentStatus.FAILED,
        transaction_id=transaction_id,
        created_at=datetime.now(ZoneInfo("Asia/Bishkek")).replace(tzinfo=None)
    )
    db.add(payment)
    
    # Update booking status if payment successful
    if payment_success:
        booking.status = BookingStatus.CONFIRMED
        # Release seat holds (seats are now confirmed)
        from app.services.seat_hold import release_holds_for_booking
        release_holds_for_booking(db, booking_id)
    
    db.commit()
    db.refresh(payment)
    
    if not payment_success:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Payment failed"
        )
    
    return payment

