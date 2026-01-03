"""
Payment service - mock payment processing with idempotency.
"""
from datetime import datetime, timezone
from sqlalchemy.orm import Session

from app.core.exceptions import PaymentFailed, NotFound
from app.models.seat import Seat
from app.repositories.payment import payment_repository
from app.repositories.booking import booking_repository
from app.repositories.ticket import ticket_repository
from app.repositories.seat_hold import seat_hold_repository
from app.services.id_generator import generate_ticket_number


class PaymentService:
    """
    Business logic for payment processing.
    
    Features:
        - Idempotency via idempotency_key
        - Mock payment (always succeeds for demo/testing)
        - Updates booking status to CONFIRMED on success
        - Links seat holds to booking (makes them permanent)
    """
    
    def process_payment(
        self,
        db: Session,
        booking_pnr: str,
        idempotency_key: str,
        payment_method: str = "MOCK_CARD"
    ):
        """
        Process payment for booking.
        
        Idempotency:
            If payment with same idempotency_key exists, returns that payment
            without processing again (prevents double-charging).
        
        Raises:
            NotFound: if booking doesn't exist
            PaymentFailed: if booking is not payable (expired hold, etc)
        """
        # Check idempotency: have we seen this key before?
        existing_payment = payment_repository.get_by_idempotency_key(db, idempotency_key)
        if existing_payment:
            # Return cached result (idempotent)
            booking = booking_repository.get_by_pnr(db, booking_pnr)
            return {
                "payment": existing_payment,
                "booking": booking
            }
        
        # Get booking
        booking = booking_repository.get_by_pnr(db, booking_pnr)
        if not booking:
            raise NotFound("Booking")

        # Booking must still be awaiting payment
        if booking.status != "CREATED" and booking.status != "CONFIRMED":
            raise PaymentFailed(f"Booking status is {booking.status}")

        # If already confirmed and idempotency key is new, do not re-charge.
        if booking.status == "CONFIRMED":
            raise PaymentFailed("Booking already paid")

        # Validate seat hold is still valid
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        holds = list(getattr(booking, "seat_holds", None) or [])
        if not holds:
            # If holds are missing, booking cannot be paid.
            raise PaymentFailed("Seat hold not found")
        latest_hold = max(h.held_until for h in holds)
        if latest_hold < now:
            # Cancel booking and release holds
            booking_repository.update_status(db, booking, "CANCELLED")
            db.query(type(holds[0])).filter(type(holds[0]).booking_id == booking.id).delete(synchronize_session=False)
            db.commit()
            raise PaymentFailed("Seat hold expired")
        
        # Mock payment processing: always succeed when payable.
        payment = payment_repository.create(
            db=db,
            booking_id=booking.id,
            idempotency_key=idempotency_key,
            amount=float(booking.total_amount),
            payment_method=payment_method,
            status="PAID",
        )
        payment.processed_at = datetime.now(timezone.utc).replace(tzinfo=None)

        # Update booking to CONFIRMED
        booking_repository.update_status(db, booking, "CONFIRMED")

        # Create tickets (seat holds become permanent via booking_id)
        for p in (booking.passengers or []):
            # Parse seat_number format: "1A", "2B", etc.
            seat_code = p.seat_number.strip()
            if not seat_code:
                raise PaymentFailed("Seat not found")
            
            # Extract row number and seat letter
            row_num = int(''.join(c for c in seat_code if c.isdigit()))
            seat_letter = ''.join(c for c in seat_code if c.isalpha()).upper()
            
            # Find seat in airplane
            seat = (
                db.query(Seat)
                .filter(Seat.airplane_id == booking.flight.airplane_id)
                .filter(Seat.row_number == row_num)
                .filter(Seat.seat_letter == seat_letter)
                .first()
            )
            if not seat:
                raise PaymentFailed("Seat not found")

            ticket_repository.create(
                db=db,
                booking_id=booking.id,
                flight_id=booking.flight_id,
                ticket_number=generate_ticket_number(),
                passenger_id=p.id,
                seat_id=seat.id,
                passenger_first_name=p.first_name,
                passenger_last_name=p.last_name,
                seat_number=p.seat_number,
                price=float(booking.flight.price),
            )

        # Remove holds after successful payment (not needed anymore)
        db.query(type(holds[0])).filter(type(holds[0]).booking_id == booking.id).delete(synchronize_session=False)

        db.commit()

        return {
            "payment": payment,
            "booking": booking,
        }


payment_service = PaymentService()
