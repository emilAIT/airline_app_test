"""
Database reset script - drops and recreates all tables.
WARNING: This will DELETE ALL DATA!
"""
import os
import sys

# Add the backend directory to the Python path
sys.path.insert(0, os.path.dirname(__file__))

from app.database import Base, engine
from app.models.airport import Airport
from app.models.airplane import Airplane
from app.models.flight import Flight
from app.models.user import User
from app.models.booking import Booking
from app.models.passenger_profile import PassengerProfile
from app.models.announcement import Announcement
from app.models.seat_template import SeatTemplate
from app.models.seat import Seat
from app.models.seat_hold import SeatHold
from app.models.ticket import Ticket
from app.models.checkin import CheckIn
from app.models.payment import Payment


def reset_database():
    """Drop all tables and recreate them."""
    print("WARNING: This will delete ALL data from the database!")
    response = input("Type 'YES' to continue: ")
    
    if response != "YES":
        print("Aborted.")
        return
    
    print("\n1. Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("   ✓ All tables dropped")
    
    print("\n2. Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("   ✓ All tables created")
    
    print("\n3. Verifying key columns...")
    from sqlalchemy import inspect
    inspector = inspect(engine)
    
    # Check Airport table
    airport_cols = [col['name'] for col in inspector.get_columns('airports')]
    print(f"   Airport columns: {airport_cols}")
    assert 'code' in airport_cols, "Airport table missing 'code' column!"
    print("   ✓ Airport.code exists")
    
    # Check Flight table
    flight_cols = [col['name'] for col in inspector.get_columns('flights')]
    print(f"   Flight columns: {flight_cols}")
    assert 'airplane_id' in flight_cols, "Flight table missing 'airplane_id' column!"
    print("   ✓ Flight.airplane_id exists")
    
    print("\n✅ Database reset complete!")
    print("\nNext steps:")
    print("1. Run: python seed.py  (to populate with sample data)")
    print("2. Restart backend server")


if __name__ == "__main__":
    reset_database()
