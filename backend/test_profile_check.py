import sys
import os
from datetime import datetime, date
from dotenv import load_dotenv

# Load .env from backend directory
backend_dir = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(backend_dir, '.env'))

# Force absolute path for sqlite
if os.environ.get("DATABASE_URL") == "sqlite:///./airline.db":
    os.environ["DATABASE_URL"] = f"sqlite:///{os.path.join(backend_dir, 'airline.db')}"
    print(f"Forced DATABASE_URL to: {os.environ['DATABASE_URL']}")

# Add the current directory to sys.path to import models and db
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from db.session import SessionLocal

def setup_test_data(db):
    from db.base import User, Flight
    # Get or create a test user
    user = db.query(User).filter_by(email="test_profile@example.com").first()
    if not user:
        user = User(email="test_profile@example.com", hashed_password="fake", role="PASSENGER")
        db.add(user)
        db.flush()
    
    # Get or create a test flight
    flight = db.query(Flight).first()
    if not flight:
        print("No flight found in DB. Please run the app or seeds first.")
        return None, None
    
    return user, flight

def test_profile_check():
    from db.base import PassengerProfile, Booking, Ticket
    
    db = SessionLocal()
    try:
        user, flight = setup_test_data(db)
        if not user or not flight:
            return

        # 1. Test incomplete profile
        if user.profile:
            db.delete(user.profile)
            db.commit()
            db.refresh(user)

        print("\n--- Testing Incomplete Profile ---")
        # In the API route we check:
        # if not user.profile or not all([user.profile.full_name, user.profile.phone, ...])
        
        def mock_check(u):
            if not u.profile or not all([
                u.profile.full_name,
                u.profile.phone,
                u.profile.passport_number,
                u.profile.nationality,
                u.profile.date_of_birth
            ]):
                return False
            return True

        print(f"Is profile complete? {mock_check(user)}")
        assert mock_check(user) == False, "Profile should be incomplete"

        # 2. Test partial profile
        profile = PassengerProfile(user_id=user.id, full_name="John Doe")
        db.add(profile)
        db.commit()
        db.refresh(user)
        print(f"Is profile (only name) complete? {mock_check(user)}")
        assert mock_check(user) == False, "Profile should still be incomplete"

        # 3. Test complete profile
        user.profile.phone = "123456789"
        user.profile.passport_number = "PP12345"
        user.profile.nationality = "Tester"
        user.profile.date_of_birth = date(1990, 1, 1)
        db.commit()
        db.refresh(user)
        print(f"Is profile (all fields) complete? {mock_check(user)}")
        assert mock_check(user) == True, "Profile should be complete now"

        # 4. Test ticket data persistence
        print("\n--- Testing Ticket Data Persistence ---")
        seat = "99Z" # Unlikely to be taken
        tickets_data = [
            {
                "passenger_name": user.profile.full_name,
                "passport_number": user.profile.passport_number,
                "nationality": user.profile.nationality,
                "seat_number": seat,
            }
        ]
        
        booking = Booking.create_booking(
            db=db,
            flight=flight,
            ticket_data=tickets_data,
            user_id=user.id
        )
        print(f"Booking created: {booking.pnr_code}")
        
        ticket = db.query(Ticket).filter_by(booking_id=booking.id).first()
        print(f"Ticket passenger: {ticket.passenger_name}")
        print(f"Ticket passport: {ticket.passport_number}")
        print(f"Ticket nationality: {ticket.nationality}")
        
        assert ticket.passport_number == "PP12345"
        assert ticket.nationality == "Tester"
        print("Success! Ticket contains profile data.")

    finally:
        db.close()

if __name__ == "__main__":
    test_profile_check()
