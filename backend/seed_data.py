"""
Seed data script for Airline Booking & Operations System
Per instructions.txt lines 255-256: seed data for airports and flights required
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from datetime import datetime, timedelta
from app.core.database import engine, Base, SessionLocal
from app.models import (
    User, UserRole,
    Airport,
    Airplane,
    Flight, FlightStatus,
    PassengerProfile
)
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def seed_database():
    print("Creating database tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    try:
        print("Seeding users...")
        # Create staff user
        staff_user = User(
            username="staff",
            email="staff@airline.com",
            hashed_password=hash_password("staff123"),
            role=UserRole.STAFF
        )
        db.add(staff_user)
        
        # Create test passenger users
        passenger1 = User(
            username="john_doe",
            email="john@example.com",
            hashed_password=hash_password("passenger123"),
            role=UserRole.PASSENGER
        )
        db.add(passenger1)
        
        passenger2 = User(
            username="jane_smith",
            email="jane@example.com",
            hashed_password=hash_password("passenger123"),
            role=UserRole.PASSENGER
        )
        db.add(passenger2)
        
        db.flush()
        
        # Create passenger profiles
        print("Seeding passenger profiles...")
        profile1 = PassengerProfile(
            user_id=passenger1.id,
            first_name="John",
            last_name="Doe",
            date_of_birth=datetime(1990, 1, 1),
            passport_number="P123456789",
            nationality="USA",
            phone_number="+1234567890"
        )
        db.add(profile1)
        
        profile2 = PassengerProfile(
            user_id=passenger2.id,
            first_name="Jane",
            last_name="Smith",
            date_of_birth=datetime(1992, 5, 15),
            passport_number="P987654321",
            nationality="USA",
            phone_number="+9876543210"
        )
        db.add(profile2)
        
        print("Seeding airports...")
        airports = [
            Airport(code="JFK", name="John F. Kennedy International Airport", city="New York", country="USA"),
            Airport(code="LAX", name="Los Angeles International Airport", city="Los Angeles", country="USA"),
            Airport(code="ORD", name="O'Hare International Airport", city="Chicago", country="USA"),
            Airport(code="LHR", name="Heathrow Airport", city="London", country="UK"),
            Airport(code="CDG", name="Charles de Gaulle Airport", city="Paris", country="France"),
            Airport(code="DXB", name="Dubai International Airport", city="Dubai", country="UAE"),
            Airport(code="SIN", name="Singapore Changi Airport", city="Singapore", country="Singapore"),
            Airport(code="HND", name="Tokyo Haneda Airport", city="Tokyo", country="Japan"),
            Airport(code="SYD", name="Sydney Kingsford Smith Airport", city="Sydney", country="Australia"),
            Airport(code="FRA", name="Frankfurt Airport", city="Frankfurt", country="Germany"),
        ]
        for airport in airports:
            db.add(airport)
        
        db.flush()
        
        print("Seeding airplanes...")
        airplanes = [
            Airplane(
                model="Boeing 737-800",
                registration_number="N12345",
                seat_template={
                    "rows": 30,
                    "seats_per_row": 6,
                    "layout": "3-3",
                    "categories": {
                        "1-5": "EXTRA_LEGROOM",
                        "6-30": "STANDARD"
                    }
                },
                total_seats=180
            ),
            Airplane(
                model="Airbus A320",
                registration_number="N67890",
                seat_template={
                    "rows": 28,
                    "seats_per_row": 6,
                    "layout": "3-3",
                    "categories": {
                        "1-4": "EXTRA_LEGROOM",
                        "5-28": "STANDARD"
                    }
                },
                total_seats=168
            ),
            Airplane(
                model="Boeing 777-300ER",
                registration_number="N11111",
                seat_template={
                    "rows": 40,
                    "seats_per_row": 9,
                    "layout": "3-3-3",
                    "categories": {
                        "1-10": "EXTRA_LEGROOM",
                        "11-40": "STANDARD"
                    }
                },
                total_seats=360
            ),
            Airplane(
                model="Airbus A350-900",
                registration_number="N22222",
                seat_template={
                    "rows": 35,
                    "seats_per_row": 9,
                    "layout": "3-3-3",
                    "categories": {
                        "1-8": "EXTRA_LEGROOM",
                        "9-35": "STANDARD"
                    }
                },
                total_seats=315
            ),
        ]
        for airplane in airplanes:
            db.add(airplane)
        
        db.flush()
        
        print("Seeding flights...")
        # Create flights for the next 7 days
        base_date = datetime.utcnow() + timedelta(days=1)
        
        flight_routes = [
            # Domestic US
            ("JFK", "LAX", airplanes[0], 6, 299.99),  # 6 hour flight
            ("LAX", "JFK", airplanes[0], 5.5, 289.99),
            ("JFK", "ORD", airplanes[1], 2.5, 149.99),
            ("ORD", "JFK", airplanes[1], 2.5, 159.99),
            ("LAX", "ORD", airplanes[0], 4, 199.99),
            ("ORD", "LAX", airplanes[0], 4.5, 209.99),
            
            # International
            ("JFK", "LHR", airplanes[2], 7, 599.99),
            ("LHR", "JFK", airplanes[2], 8, 649.99),
            ("LAX", "HND", airplanes[3], 11, 899.99),
            ("HND", "LAX", airplanes[3], 10, 849.99),
            ("JFK", "CDG", airplanes[2], 7.5, 549.99),
            ("CDG", "JFK", airplanes[2], 8.5, 579.99),
            ("LHR", "DXB", airplanes[3], 7, 699.99),
            ("DXB", "LHR", airplanes[3], 7.5, 729.99),
            ("SIN", "SYD", airplanes[2], 8, 499.99),
            ("SYD", "SIN", airplanes[2], 8, 479.99),
        ]
        
        flight_number_counter = 1000
        for day_offset in range(7):  # Create flights for next 7 days
            flight_date = base_date + timedelta(days=day_offset)
            
            for origin_code, dest_code, airplane, duration_hours, price in flight_routes:
                origin = next(a for a in airports if a.code == origin_code)
                dest = next(a for a in airports if a.code == dest_code)
                
                # Morning flight
                departure = flight_date.replace(hour=8, minute=0, second=0, microsecond=0)
                arrival = departure + timedelta(hours=duration_hours)
                
                flight = Flight(
                    flight_number=f"AA{flight_number_counter}",
                    origin_id=origin.id,
                    destination_id=dest.id,
                    airplane_id=airplane.id,
                    scheduled_departure=departure,
                    scheduled_arrival=arrival,
                    price=price,
                    gate=f"A{(flight_number_counter % 20) + 1}",
                    terminal="1",
                    status=FlightStatus.SCHEDULED
                )
                db.add(flight)
                flight_number_counter += 1
                
                # Evening flight
                departure_evening = flight_date.replace(hour=18, minute=30, second=0, microsecond=0)
                arrival_evening = departure_evening + timedelta(hours=duration_hours)
                
                flight_evening = Flight(
                    flight_number=f"AA{flight_number_counter}",
                    origin_id=origin.id,
                    destination_id=dest.id,
                    airplane_id=airplane.id,
                    scheduled_departure=departure_evening,
                    scheduled_arrival=arrival_evening,
                    price=price + 50,  # Evening flights slightly more expensive
                    gate=f"B{(flight_number_counter % 20) + 1}",
                    terminal="2",
                    status=FlightStatus.SCHEDULED
                )
                db.add(flight_evening)
                flight_number_counter += 1
        
        db.commit()
        print("✅ Database seeded successfully!")
        print("\nTest Credentials:")
        print("┌─────────────────────────────────────────┐")
        print("│ Staff User                              │")
        print("│  Username: staff                        │")
        print("│  Password: staff123                     │")
        print("├─────────────────────────────────────────┤")
        print("│ Passenger Users                         │")
        print("│  Username: john_doe                     │")
        print("│  Password: passenger123                 │")
        print("│                                         │")
        print("│  Username: jane_smith                   │")
        print("│  Password: passenger123                 │")
        print("└─────────────────────────────────────────┘")
        print(f"\nSeeded {len(airports)} airports")
        print(f"Seeded {len(airplanes)} airplanes")
        print(f"Seeded ~{flight_number_counter - 1000} flights")
        
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
