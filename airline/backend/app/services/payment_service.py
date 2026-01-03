from sqlalchemy.orm import Session
from app.models.all_models import Payment, PaymentStatus, PaymentMethod, Booking, BookingStatus
from app.services.booking_service import confirm_booking
from app.core.config import settings
from datetime import datetime
import uuid
import time
import random
import stripe

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


def create_payment(
    db: Session,
    booking_id: int,
    method: PaymentMethod,
    transaction_id: str = None
) -> Payment:
    """Create a payment record"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    if booking.status == BookingStatus.EXPIRED:
        raise ValueError("Cannot pay for expired booking")


    # Check if payment already exists
    existing_payment = db.query(Payment).filter(
        Payment.booking_id == booking_id).first()
    if existing_payment:
        if existing_payment.status == PaymentStatus.PAID:
            return existing_payment  # Idempotent: already paid
        # Update existing payment
        existing_payment.method = method
        existing_payment.transaction_id = transaction_id or str(uuid.uuid4())
        existing_payment.status = PaymentStatus.PAID
        db.commit()
        db.refresh(existing_payment)
        # Confirm booking
        confirm_booking(db, booking_id)
        return existing_payment

    # Calculate total amount
    total_amount = booking.flight.base_price * len(booking.tickets)

    payment = Payment(
        booking_id=booking_id,
        amount=total_amount,
        currency="USD",
        method=method,
        status=PaymentStatus.PAID,  # Mock payment always succeeds
        transaction_id=transaction_id or str(uuid.uuid4()),
        created_at=datetime.utcnow()
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    # Confirm booking
    confirm_booking(db, booking_id)
    return payment


def create_payment_intent(
    db: Session,
    booking_id: int,
    method: PaymentMethod
) -> dict:
    """Create a Stripe Payment Intent"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    # Calculate total amount in cents (Stripe uses cents)
    total_amount = booking.flight.base_price * len(booking.tickets)
    amount_cents = int(total_amount * 100)

    try:
        # Create Payment Intent
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency='usd',
            payment_method_types=['card'],
            metadata={
                'booking_id': str(booking_id),
                'pnr': booking.pnr,
                'flight_number': booking.flight.flight_number,
            }
        )

        return {
            'client_secret': intent.client_secret,
            'payment_intent_id': intent.id,
            'amount': total_amount,
            'currency': 'USD'
        }
    except stripe.error.StripeError as e:
        raise ValueError(f"Stripe error: {str(e)}")


def confirm_stripe_payment(
    db: Session,
    booking_id: int,
    payment_intent_id: str,
    method: PaymentMethod
) -> Payment:
    """Confirm a Stripe payment and create payment record"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    try:
        # Retrieve the payment intent to verify it was successful
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        if intent.status != 'succeeded':
            raise ValueError(f"Payment not completed. Status: {intent.status}")

        # Create payment record with Stripe transaction ID
        return create_payment(
            db=db,
            booking_id=booking_id,
            method=method,
            transaction_id=payment_intent_id
        )
    except stripe.error.StripeError as e:
        raise ValueError(f"Stripe error: {str(e)}")


def process_mock_payment(
    db: Session,
    booking_id: int,
    method: PaymentMethod,
    card_number: str = None,
    card_holder: str = None,
    expiry_month: int = None,
    expiry_year: int = None,
    cvv: str = None,
    payment_intent_id: str = None
) -> Payment:
    """Process payment - 100% MOCKED for all methods (CARD, APPLE_PAY, GOOGLE_PAY)"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise ValueError("Booking not found")

    # ALL PAYMENT METHODS ARE 100% MOCKED - No real Stripe/Apple Pay/Google Pay
    # Simply create payment record and confirm booking
    return create_payment(db, booking_id, method)
