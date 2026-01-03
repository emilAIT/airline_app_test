from app.database import SessionLocal
from app.models.all_models import Booking, User, Flight, CancellationRule, BookingStatus
from app.services.cancellation_service import evaluate_cancellation
from datetime import datetime, timedelta, timezone

def test_cancellation_logic():
    print("Testing Cancellation Logic...")
    db = SessionLocal()
    
    # 1. Setup Dummy Flight & Booking
    now = datetime.now(timezone.utc)
    
    # Mock objects (not saving to DB to avoid pollution, or maybe saving is needed for relationships)
    # We will use objects attached to session but rolled back? 
    # Or just mock properties if service allows. Service access .flight.departure_time
    
    # Let's create a real rule to be sure
    rule = db.query(CancellationRule).filter_by(min_hours_before_departure=24).first()
    if not rule:
        print("Creating temp rule...")
        rule = CancellationRule(min_hours_before_departure=24, refund_percent=1.0, cancellation_allowed=True, description="Full Refund")
        db.add(rule)
        db.commit()

    # Create Flight departing in 25 hours
    flight_25h = Flight(
        departure_time=now + timedelta(hours=25),
        arrival_time=now + timedelta(hours=28),
        base_price=100.0,
        flight_number="TEST-25H"
    )
    
    # Create Flight departing in 5 hours (should match 3h-24h rule)
    flight_5h = Flight(
        departure_time=now + timedelta(hours=5),
        arrival_time=now + timedelta(hours=8),
        base_price=100.0,
        flight_number="TEST-5H"
    )

    # Booking 1 (>24h)
    b1 = Booking(flight=flight_25h, status=BookingStatus.CONFIRMED)
    
    print("Evaluating >24h booking...")
    res1 = evaluate_cancellation(db, b1)
    print(f"Result >24h: {res1}")
    assert res1['allowed'] == True
    assert res1['refund_percent'] == 1.0


    # Booking 2 (5h, should be 90%)
    b2 = Booking(flight=flight_5h, status=BookingStatus.CONFIRMED)
    print("Evaluating 5h booking...")
    res2 = evaluate_cancellation(db, b2)
    print(f"Result 5h: {res2}")
    
    # Check if 90% rule exists
    rule_90 = db.query(CancellationRule).filter_by(min_hours_before_departure=3).first()
    if rule_90:
        assert res2['allowed'] == True
        assert res2['refund_percent'] == 0.9
    else:
        print("Skipping 90% check (rule missing)")

    print("Success!")

if __name__ == "__main__":
    test_cancellation_logic()
