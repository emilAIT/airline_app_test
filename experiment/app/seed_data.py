"""
Seed script for initializing database with sample data.
Run this script after starting the server to populate the database.
"""
import sys
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.core.database import SessionLocal, engine, Base
from app.models import aviation, flight, user as user_model
from app.core import security

# Create all tables
Base.metadata.create_all(bind=engine)

def seed_data():
    db: Session = SessionLocal()
    
    try:
        # Check if data already exists
        existing_airports = db.query(aviation.Airport).count()
        if existing_airports > 0:
            print("Database already contains data. Skipping seed.")
            return
        
        print("Seeding database...")
        
        # Create Airports
        airports_data = [
            {"code": "JFK", "name": "John F. Kennedy International Airport", "city": "New York", "country": "USA"},
            {"code": "LHR", "name": "London Heathrow Airport", "city": "London", "country": "UK"},
            {"code": "CDG", "name": "Charles de Gaulle Airport", "city": "Paris", "country": "France"},
            {"code": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "UAE"},
            {"code": "SVO", "name": "Sheremetyevo International Airport", "city": "Moscow", "country": "Russia"},
        ]
        
        for airport_data in airports_data:
            airport = aviation.Airport(**airport_data)
            db.add(airport)
        db.commit()
        print(f"Created {len(airports_data)} airports")
        
        # Create Airplanes with seats
        airplanes_data = [
            {
                "name": "B777-001",
                "model": "Boeing 777",
                "rows": 30,
                "seats_per_row": 6,
                "business_rows": 5
            },
            {
                "name": "A320-002",
                "model": "Airbus A320",
                "rows": 20,
                "seats_per_row": 4,
                "business_rows": 3
            },
        ]
        
        letters = "ABCDEFGHJK"
        
        for ap_data in airplanes_data:
            airplane = aviation.Airplane(
                name=ap_data["name"],
                model=ap_data["model"]
            )
            db.add(airplane)
            db.flush()  # Get ID
            
            # Generate seats
            seats = []
            for r in range(1, ap_data["rows"] + 1):
                for c in range(ap_data["seats_per_row"]):
                    seat_letter = letters[c]
                    seat_num = f"{r}{seat_letter}"
                    category = "Business" if r <= ap_data["business_rows"] else "Economy"
                    seat = aviation.Seat(
                        airplane_id=airplane.id,
                        seat_number=seat_num,
                        category=category
                    )
                    seats.append(seat)
            
            db.add_all(seats)
        
        db.commit()
        print(f"Created {len(airplanes_data)} airplanes with seats")
        
        # Get created airplanes
        airplanes = db.query(aviation.Airplane).all()
        
        # Create Flights
        now = datetime.utcnow()
        flights_data = [
            {
                "flight_number": "AA101",
                "departure_airport_code": "JFK",
                "arrival_airport_code": "LHR",
                "airplane_id": airplanes[0].id,
                "departure_time": now + timedelta(days=1, hours=10),
                "arrival_time": now + timedelta(days=1, hours=18),
                "base_price": 500.0,
                "gate": "A1",
                "terminal": "T1"
            },
            {
                "flight_number": "AA102",
                "departure_airport_code": "LHR",
                "arrival_airport_code": "CDG",
                "airplane_id": airplanes[1].id,
                "departure_time": now + timedelta(days=2, hours=14),
                "arrival_time": now + timedelta(days=2, hours=15, minutes=30),
                "base_price": 200.0,
                "gate": "B2",
                "terminal": "T2"
            },
            {
                "flight_number": "AA103",
                "departure_airport_code": "CDG",
                "arrival_airport_code": "DXB",
                "airplane_id": airplanes[0].id,
                "departure_time": now + timedelta(days=3, hours=8),
                "arrival_time": now + timedelta(days=3, hours=16),
                "base_price": 600.0,
                "gate": "C3",
                "terminal": "T1"
            },
        ]
        
        for flight_data in flights_data:
            flight_obj = flight.Flight(**flight_data)
            db.add(flight_obj)
        
        db.commit()
        print(f"Created {len(flights_data)} flights")
        
        print("\n✅ Seed data created successfully!")
        print("\nYou can now:")
        print("1. Register users via POST /api/v1/auth/register")
        print("2. Create staff user with role='staff'")
        print("3. Use the API endpoints to manage bookings and flights")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding data: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()

