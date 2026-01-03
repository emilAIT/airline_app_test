from sqlalchemy.orm import Session
from app.models.all_models import Booking, CancellationPolicy, Refund, BookingStatus, Flight
from datetime import datetime, timezone

def get_active_policy(db: Session):
    """Returns the currently active CancellationPolicy or None."""
    return db.query(CancellationPolicy).filter(CancellationPolicy.is_active == True).first()


def can_cancel_booking(db: Session, booking: Booking, policy: CancellationPolicy):
    """
    Check if a booking can be cancelled based on policy and time.
    Returns (allowed: bool, reason: str or None).
    """
    now = datetime.now(timezone.utc)
    
    flight = booking.flight
    if not flight:
        return False, "Flight not found"

    departure = flight.departure_time
    if departure.tzinfo is None:
        departure = departure.replace(tzinfo=timezone.utc)
    
    diff = departure - now
    hours_left = diff.total_seconds() / 3600

    if hours_left < policy.min_hours_before_departure:
        return False, f"Cancellation window expired. Must cancel at least {policy.min_hours_before_departure}h before departure."

    return True, None


def evaluate_cancellation(db: Session, booking: Booking):
    """
    Evaluate if a booking can be cancelled and what the refund amount is.
    Returns a dict with 'allowed', 'description', 'refund_amount'.
    """
    # 1. Basic checks
    if booking.status == BookingStatus.REFUNDED:
        return {"allowed": False, "description": "Booking already refunded", "refund_amount": 0.0}
    
    if booking.status == BookingStatus.CANCELLED:
        return {"allowed": False, "description": "Booking already cancelled", "refund_amount": 0.0}

    if booking.status in [BookingStatus.EXPIRED, BookingStatus.COMPLETED]:
        return {"allowed": False, "description": f"Cannot cancel {booking.status.value.lower()} booking", "refund_amount": 0.0}

    # 2. Get Policy
    policy = get_active_policy(db)
    if not policy:
        return {"allowed": False, "description": "No active cancellation policy found. Contact support.", "refund_amount": 0.0}

    # 3. Check time
    allowed, reason = can_cancel_booking(db, booking, policy)
    if not allowed:
        return {"allowed": False, "description": reason, "refund_amount": 0.0}

    # 4. Calculate Refund
    paid_amount = 0.0
    if booking.payment and booking.payment.status == "PAID":
        paid_amount = booking.payment.amount
    
    fee = paid_amount * (policy.refund_fee_percent / 100.0)
    refund_amount = round(paid_amount - fee, 2)
    
    return {
        "allowed": True,
        "description": f"Full refund available (fee: {policy.refund_fee_percent}%)",
        "refund_amount": refund_amount
    }


def process_refund(db: Session, booking: Booking, method: str, card_last4: str = None, card_holder: str = None):
    """
    Create Refund entry and mark booking as CANCELLED.
    """
    # 1. Fetch Paid Amount
    paid_amount = 0.0
    if booking.payment and booking.payment.status == "PAID":
        paid_amount = booking.payment.amount
    
    policy = get_active_policy(db)
    fee = paid_amount * (policy.refund_fee_percent / 100.0) if policy else 0.0
    refund_amount = round(paid_amount - fee, 2)

    # 2. Create Refund Record
    refund = Refund(
        booking_id=booking.id,
        method=method,
        card_last4=card_last4,
        card_holder=card_holder,
        status="COMPLETED"  # In real app, this would be PENDING then async webhook
    )
    db.add(refund)
    
    # 3. Update Booking Status
    booking.status = BookingStatus.CANCELLED
    
    db.commit()
    db.refresh(refund)
    db.refresh(booking)
    
    return refund_amount
