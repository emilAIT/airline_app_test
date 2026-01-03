"""
Seed data script for Airline Booking System
Run this script to populate the database with initial data
"""
from sqlalchemy.orm import Session
from app.db.session import SessionLocal, engine
from app.db.base import Base
from app.models.user import User, UserRole
from app.models.airport import Airport
from app.models.airplane import Airplane, SeatTemplate
from app.models.flight import Flight, FlightStatus
from app.utils.security import get_password_hash
from app.core.config import settings
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# Create all tables
Base.metadata.create_all(bind=engine)

db: Session = SessionLocal()


def seed_airports():
    """Seed airports data"""
    airports_data = [
        {"code": "IST", "name": "Istanbul Airport", "city": "Istanbul", "country": "Turkey"},
        {"code": "JFK", "name": "John F. Kennedy International Airport", "city": "New York", "country": "USA"},
        {"code": "LHR", "name": "London Heathrow Airport", "city": "London", "country": "UK"},
        {"code": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "UAE"},
    ]
    
    for airport_data in airports_data:
        existing = db.query(Airport).filter(Airport.code == airport_data["code"]).first()
        if not existing:
            airport = Airport(**airport_data)
            db.add(airport)
    
    db.commit()
    print("✓ Airports seeded")


def seed_seat_templates():
    """Seed seat templates"""
    templates_data = [
        {
            "name": "Boeing 737-800 Standard",
            "rows": 30,
            "seats_per_row": 6,
            "seat_labels": ["A", "B", "C", "D", "E", "F"],
            "seat_categories": {"1-2": "BUSINESS", "3-6": "EXTRA_LEGROOM", "7-30": "ECONOMY"}
        },
        {
            "name": "Airbus A320 Standard",
            "rows": 29,
            "seats_per_row": 6,
            "seat_labels": ["A", "B", "C", "D", "E", "F"],
            "seat_categories": {"1-2": "BUSINESS", "3-6": "EXTRA_LEGROOM", "7-29": "ECONOMY"}
        },
        {
            "name": "Boeing 777-300ER Wide",
            "rows": 40,
            "seats_per_row": 9,
            "seat_labels": ["A", "B", "C", "D", "E", "F", "G", "H", "J"],
            "seat_categories": {"1-4": "BUSINESS", "5-10": "EXTRA_LEGROOM", "11-40": "ECONOMY"}
        }
    ]
    
    for template_data in templates_data:
        existing = db.query(SeatTemplate).filter(SeatTemplate.name == template_data["name"]).first()
        if not existing:
            template = SeatTemplate(**template_data)
            db.add(template)
    
    db.commit()
    print("✓ Seat templates seeded")


def seed_airplanes():
    """Seed airplanes"""
    templates = db.query(SeatTemplate).all()
    if not templates:
        print("⚠ No seat templates found. Please seed templates first.")
        return
    
    airplanes_data = [
        {"model": "Boeing 737-800", "registration_number": "TC-ABC", "seat_template_id": templates[0].id},
        {"model": "Boeing 737-800", "registration_number": "TC-DEF", "seat_template_id": templates[0].id},
        {"model": "Airbus A320", "registration_number": "TC-GHI", "seat_template_id": templates[1].id},
        {"model": "Boeing 777-300ER", "registration_number": "TC-JKL", "seat_template_id": templates[2].id},
    ]
    
    for airplane_data in airplanes_data:
        existing = db.query(Airplane).filter(
            Airplane.registration_number == airplane_data["registration_number"]
        ).first()
        if not existing:
            airplane = Airplane(**airplane_data)
            db.add(airplane)
    
    db.commit()
    print("✓ Airplanes seeded")


def seed_flights():
    """Seed flights"""
    airports = db.query(Airport).all()
    airplanes = db.query(Airplane).all()
    
    if len(airports) < 2 or not airplanes:
        print("⚠ Not enough airports or airplanes. Please seed them first.")
        return
    
    # Create flights for the next 7 days
    now = datetime.now(ZoneInfo("Asia/Bishkek")).replace(tzinfo=None, second=0, microsecond=0)
    
    flights_data = []
    flight_numbers = ["TK001", "TK002", "TK101", "TK102", "TK201", "TK202"]
    
    # Create exactly 5 flights
    flight_configs = [
        {"num": "TK001", "day": 0, "hour": 2},
        {"num": "TK002", "day": 1, "hour": 5},
        {"num": "TK101", "day": 2, "hour": 8},
        {"num": "TK102", "day": 3, "hour": 11},
        {"num": "TK201", "day": 4, "hour": 14},
    ]
    
    for i, config in enumerate(flight_configs):
        origin_idx = i % len(airports)
        dest_idx = (i + 1) % len(airports)
        
        departure = now + timedelta(days=config["day"], hours=config["hour"])
        arrival = departure + timedelta(hours=3)
        
        base_price = 150.0 + (i * 50)
        flights_data.append({
            "flight_number": config["num"],
            "origin_airport_id": airports[origin_idx].id,
            "destination_airport_id": airports[dest_idx].id,
            "airplane_id": airplanes[i % len(airplanes)].id,
            "departure_time": departure,
            "arrival_time": arrival,
            "price": base_price,
            "category_prices": f'{{"BUSINESS": {base_price * 3}, "EXTRA_LEGROOM": {base_price * 1.5}, "ECONOMY": {base_price}}}',
            "gate": f"Gate {chr(65 + (i % 10))}",
            "terminal": "T1" if i % 2 == 0 else "T2",
            "status": FlightStatus.SCHEDULED
        })
    
    for flight_data in flights_data:
        existing = db.query(Flight).filter(Flight.flight_number == flight_data["flight_number"]).first()
        if not existing:
            flight = Flight(**flight_data)
            db.add(flight)
    
    db.commit()
    print("✓ Flights seeded")


def seed_admin_user():
    """Seed admin/staff user"""
    existing = db.query(User).filter(User.email == settings.ADMIN_EMAIL).first()
    if not existing:
        admin_user = User(
            email=settings.ADMIN_EMAIL,
            hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
            role=UserRole.ADMIN,
            is_approved=True,
            is_active=True
        )
        db.add(admin_user)
        db.commit()
        print(f"✓ Admin user created: {settings.ADMIN_EMAIL} / {settings.ADMIN_PASSWORD}")
    else:
        print(f"✓ Admin user already exists: {settings.ADMIN_EMAIL}")


def seed_staff_user():
    """Seed a default staff user"""
    staff_email = "staff@airline.com"
    staff_password = "staff123"
    existing = db.query(User).filter(User.email == staff_email).first()
    if not existing:
        staff_user = User(
            email=staff_email,
            hashed_password=get_password_hash(staff_password),
            role=UserRole.STAFF,
            is_approved=True,
            is_active=True
        )
        db.add(staff_user)
        db.commit()
        print(f"✓ Staff user created: {staff_email} / {staff_password}")
    else:
        print(f"✓ Staff user already exists: {staff_email}")


def seed_pending_staff_user():
    """Seed a pending staff user for testing approval flow"""
    staff_password = "staff123"
    for email in ["pending_staff@airline.com", "pending_staff2@airline.com"]:
        existing = db.query(User).filter(User.email == email).first()
        if not existing:
            staff_user = User(
                email=email,
                hashed_password=get_password_hash(staff_password),
                role=UserRole.STAFF,
                is_approved=False,
                is_active=True
            )
            db.add(staff_user)
            db.commit()
            print(f"✓ Pending Staff user created: {email} / {staff_password}")
        else:
            print(f"✓ Pending Staff user already exists: {email}")


def main():
    """Main seeding function"""
    print("Starting database seeding...")
    print("-" * 50)
    
    try:
        seed_airports()
        seed_seat_templates()
        seed_airplanes()
        seed_flights()
        seed_admin_user()
        seed_staff_user()
        seed_pending_staff_user()
        
        print("-" * 50)
        print("✓ Database seeding completed successfully!")
        print(f"\nAdmin credentials:")
        print(f"  Email: {settings.ADMIN_EMAIL}")
        print(f"  Password: {settings.ADMIN_PASSWORD}")
        
    except Exception as e:
        print(f"✗ Error during seeding: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()

