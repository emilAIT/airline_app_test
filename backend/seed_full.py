"""
Full seed script for Hard Reset.
Creates airports, airplanes, and auto-generates seats.
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy.orm import Session
from app.database import engine, Base
from app.models.airport import Airport
from app.models.airplane import Airplane
from app.models.seat import Seat
from app.models.user import User
from app.core.security import hash_password


def create_airports(db: Session):
    """Create 3 airports."""
    airports = [
        Airport(
            code="ALA",
            name="Almaty International Airport",
            city="Almaty"
        ),
        Airport(
            code="DEL",
            name="Indira Gandhi International Airport",
            city="Delhi"
        ),
        Airport(
            code="CIT",
            name="Shymkent International Airport",
            city="Shymkent"
        ),
    ]
    
    for airport in airports:
        db.add(airport)
    
    db.commit()
    print("✅ Created 3 airports: ALA, DEL, CIT")


def create_airplane_with_seats(db: Session):
    """Create 1 Boeing 737 airplane and auto-generate 10 rows x 6 seats."""
    airplane = Airplane(
        registration_number="UP-B7701",
        model="Boeing 737-800",
        manufacturer="Boeing",
        total_seats=60  # 10 rows x 6 seats
    )
    
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    
    print(f"✅ Created airplane: {airplane.model} (ID: {airplane.id})")
    
    # Auto-generate seats: 10 rows (1-10) x 6 letters (A-F)
    seat_letters = ['A', 'B', 'C', 'D', 'E', 'F']
    seats_created = 0
    
    for row in range(1, 11):  # Rows 1 to 10
        # Rows 1-3 are extra_legroom
        category = 'extra_legroom' if row <= 3 else 'standard'
        
        for letter in seat_letters:
            seat = Seat(
                airplane_id=airplane.id,
                row_number=row,
                seat_letter=letter,
                category=category
            )
            db.add(seat)
            seats_created += 1
    
    db.commit()
    print(f"✅ Created {seats_created} seats (rows 1-3: extra_legroom, rows 4-10: standard)")


def create_users(db: Session):
    """Create staff and passenger users."""
    users = [
        User(
            email="staff@zaku.kz",
            hashed_password=hash_password("staff123"),
            role="STAFF",
            is_active=True
        ),
        User(
            email="passenger@zaku.kz",
            hashed_password=hash_password("passenger123"),
            role="PASSENGER",
            is_active=True
        ),
    ]
    
    for user in users:
        db.add(user)
    
    db.commit()
    print("✅ Created users: staff@zaku.kz, passenger@zaku.kz")


def main():
    """Main seed function."""
    print("🔄 Starting Full Seed...")
    
    # Drop and recreate all tables
    print("⚠️  Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    
    print("🏗️  Creating all tables...")
    Base.metadata.create_all(bind=engine)
    
    # Create a session
    db = Session(bind=engine)
    
    try:
        create_airports(db)
        create_airplane_with_seats(db)
        create_users(db)
        
        print("\n✅ Full seed completed successfully!")
        print("\n📊 Database summary:")
        print(f"   - Airports: {db.query(Airport).count()}")
        print(f"   - Airplanes: {db.query(Airplane).count()}")
        print(f"   - Seats: {db.query(Seat).count()}")
        print(f"   - Users: {db.query(User).count()}")
        
    except Exception as e:
        print(f"\n❌ Error during seed: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
