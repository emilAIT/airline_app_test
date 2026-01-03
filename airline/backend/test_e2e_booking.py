import sys
import os
from datetime import datetime, timedelta, timezone
import random

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.all_models import Base, Booking, User, Flight, Seat, SeatHold, BookingStatus, UserRole, SeatCategory, Airplane, Airport, FlightStatus
from app.services.booking_service import create_booking, expire_bookings
from app.services.payment_service import process_mock_payment

# Setup DB
DB_URL = "sqlite:///backend/airline.db"
engine = create_engine(DB_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

def setup_test_data():
    print("Setting up test data...")
    # Ensure a passenger user exists
    user = db.query(User).filter_by(email="test@example.com").first()
    if not user:
        user = User(email="test@example.com", hashed_password="pw", full_name="Test User", role=UserRole.PASSENGER)
        db.add(user)
        db.commit()
    
    # Ensure a flight exists with seats
    flight = db.query(Flight).join(Seat).filter(Seat.is_available == True).first()
    if not flight:
        print(" Creating dummy flight...")
        # Need airplane and airports first
        from app.models.all_models import Airplane, Airport, FlightStatus
        
        airplane = db.query(Airplane).first()
        if not airplane:
            airplane = Airplane(model="Boeing 737", total_seats=150, seat_config='{"rows":25}')
            db.add(airplane)
            db.flush()
            
        origin = db.query(Airport).filter_by(code="JFK").first()
        if not origin:
            origin = Airport(code="JFK", name="John F Kennedy", city="New York", country="USA")
            db.add(origin)
            
        dest = db.query(Airport).filter_by(code="LHR").first()
        if not dest:
            dest = Airport(code="LHR", name="Heathrow", city="London", country="UK")
            db.add(dest)
            
        db.flush()
        
        import random
        random_suffix = random.randint(1000, 9999)
        flight = Flight(
            flight_number=f"TEST-{random_suffix}",
            origin_id=origin.id,
            destination_id=dest.id,
            airplane_id=airplane.id,
            departure_time=datetime.now(timezone.utc) + timedelta(days=1),
            arrival_time=datetime.now(timezone.utc) + timedelta(days=1, hours=8),
            base_price=500.0,
            status=FlightStatus.SCHEDULED
        )
        db.add(flight)
        db.commit()
        db.refresh(flight)
        db.refresh(flight)

        # Generate seats
        print(" Generating seats...")
        print(" Generating seats...")
        for row in range(1, 6): # 5 rows
            for col in ['A', 'B', 'C']:
                seat = Seat(
                    flight_id=flight.id,
                    row=row,
                    column=col,
                    seat_number=f"{row}{col}",
                    category=SeatCategory.STANDARD,
                    is_available=True
                )
                db.add(seat)
        db.commit()
        
    return user, flight

def test_expiration_flow(user, flight_id):
    print("\n--- TEST SCENARIO 1: Expiration Flow ---")
    
    # 1. Create booking
    print(f"Creating booking for flight {flight_id}...")
    tickets_data = [{"passenger_name": "Test Passenger", "seat_number": None}] # Auto-assign
    try:
        booking = create_booking(db, user.id, flight_id, tickets_data, hold_seats=True)
        print(f"✅ Booking created: ID={booking.id}, PNR={booking.pnr}, Status={booking.status}")
    except Exception as e:
        print(f"❌ Failed to create booking: {e}")
        return

    # Check SeatHold
    holds = db.query(SeatHold).filter_by(booking_id=booking.id).all()
    if holds:
        print(f"✅ Seat holds created: {len(holds)} seats held until {holds[0].held_until}")
    else:
        print("❌ No seat holds found!")

    # 2. Manually expire it (simulate time pass)
    print("Simulating time passing (manually updating hold_until to past)...")
    booking.hold_until = datetime.now(timezone.utc) - timedelta(minutes=1)
    # Also update seat holds to be in past
    for hold in db.query(SeatHold).filter_by(booking_id=booking.id).all():
        hold.held_until = datetime.now(timezone.utc) - timedelta(minutes=1)
    db.commit()

    # 3. Trigger expiration
    print("Running expire_bookings()...")
    count = expire_bookings(db)
    print(f"Expired {count} bookings.")

    # 4. Verify Status
    db.refresh(booking)
    if booking.status == BookingStatus.EXPIRED:
        print(f"✅ Booking status is now EXPIRED")
    else:
        print(f"❌ Booking status is {booking.status} (Expected EXPIRED)")

    # 5. Verify SeatHold released
    holds = db.query(SeatHold).filter_by(booking_id=booking.id).all()
    if not holds:
        print("✅ Seat holds removed")
    else:
        print(f"❌ Seat holds still exist: {len(holds)}")

    # 6. Attempt Payment (Should fail)
    print("Attempting payment on expired booking...")
    try:
        process_mock_payment(db, booking.id, "CARD", "1234", "Holder", 12, 2030, "123")
        print("❌ Payment succeeded but should have failed!")
    except Exception as e:
        print(f"✅ Payment failed as expected: {e}")


def test_payment_flow(user, flight_id):
    print("\n--- TEST SCENARIO 2: Payment Flow ---")
    
    # 1. Create booking
    tickets_data = [{"passenger_name": "Test Passenger 2", "seat_number": None}]
    booking = create_booking(db, user.id, flight_id, tickets_data, hold_seats=True)
    print(f"✅ Booking created: ID={booking.id}, Status={booking.status}")

    # 2. Process Payment
    print("Processing payment...")
    try:
        process_mock_payment(db, booking.id, "CARD", "4242", "Valid Holder", 12, 2030, "123")
        print("✅ Payment successful")
    except Exception as e:
        print(f"❌ Payment failed: {e}")
        return

    # 3. Verify Status
    db.refresh(booking)
    if booking.status == BookingStatus.CONFIRMED:
        print("✅ Booking status is CONFIRMED")
    else:
        print(f"❌ Booking status is {booking.status}")

    # 4. Verify Hold Cleared
    if booking.hold_until is None:
        print("✅ hold_until is None (Cleared)")
    else:
        print(f"❌ hold_until is still set: {booking.hold_until}")

    # 5. Verify Seats Unavailable
    for ticket in booking.tickets:
        seat = db.query(Seat).filter_by(flight_id=booking.flight_id, seat_number=ticket.seat_number).first()
        if seat and not seat.is_available:
             print(f"✅ Seat {ticket.seat_number} marked unavailable")
        else:
             print(f"❌ Seat {ticket.seat_number} is available (Should be unavailable)")

try:
    user, flight = setup_test_data()
    test_expiration_flow(user, flight.id)
    test_payment_flow(user, flight.id)
finally:
    db.close()
