import sys
import os
from datetime import datetime, timedelta, timezone
from app.database import SessionLocal
from app.services.booking_service import create_booking, confirm_booking
from app.services.cancellation_service import evaluate_cancellation, process_refund
from app.models.all_models import Flight, BookingStatus, FlightStatus, User, UserRole, Booking
from app.schemas.schemas import RefundRequest

def test_full_cancellation_flow():
    print("--- E2E Cancellation Flow Test ---")
    db = SessionLocal()

    # 1. Setup Data
    user = db.query(User).filter(User.email == "test@example.com").first()
    if not user:
        print("Using first available user or failing...")
        user = db.query(User).first()
    
    # Create Flight departing in 48 hours (100% refund)
    flight = Flight(
        departure_time=datetime.now(timezone.utc) + timedelta(hours=48),
        arrival_time=datetime.now(timezone.utc) + timedelta(hours=50),
        base_price=200.0,
        flight_number="CANCEL-TEST",
        status=FlightStatus.SCHEDULED
    )
    # We need a placeholder for airport/airplane if strict constraints exist, 
    # but let's assume loose constraints for unit test objects or attach existing ones
    # If constraints are strict, we might fail. Let's try to query existing.
    airplane = db.query(Flight).first().airplane  # borrows existing
    origin = db.query(Flight).first().origin
    dest = db.query(Flight).first().destination
    
    flight.airplane_id = airplane.id
    flight.origin_id = origin.id
    flight.destination_id = dest.id
    
    db.add(flight)
    db.commit()
    db.refresh(flight)
    print(f"Created Flight {flight.flight_number} departing in 48h")
    
    # 2. Create Booking
    booking = create_booking(
        db=db,
        user_id=user.id,
        flight_id=flight.id,
        tickets_data=[{"passenger_name": "Test Cancel", "seat_number": "1A"}],
        hold_seats=True
    )
    print(f"Created Booking {booking.pnr} (Status: {booking.status})")

    # 3. Confirm Booking (Pay)
    confirm_booking(db, booking.id)
    print(f"Confirmed Booking {booking.pnr} (Status: {booking.status})")
    
    # 4. Check Cancellation Info
    info = evaluate_cancellation(db, booking)
    print(f"Cancellation Info: {info}")
    assert info['allowed'] == True
    assert info['refund_percent'] == 1.0

    # 5. Process Cancel (Simulate Endpoint logic)
    print("Processing Cancellation...")
    process_refund(db, booking, 200.0) # Full refund
    
    # Verify
    db.refresh(booking)
    print(f"Booking Status: {booking.status}")
    assert booking.status == BookingStatus.REFUNDED
    
    print("✅ E2E Cancellation Flow Passed")

if __name__ == "__main__":
    test_full_cancellation_flow()
