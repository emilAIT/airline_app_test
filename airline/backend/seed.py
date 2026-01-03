from app.database import SessionLocal, engine
from app.models.all_models import (
    Base, Airport, Airplane, User, UserRole, Flight, FlightStatus
)
from datetime import datetime, timedelta
from app.auth.auth_handler import hash_password
import json

Base.metadata.create_all(bind=engine)
db = SessionLocal()


def seed_data():
    # 1. Airports
    airports_data = [
        {"code": "FRU", "name": "Manas International",
            "city": "Bishkek", "country": "Kyrgyzstan"},
        {"code": "DXB", "name": "Dubai International",
            "city": "Dubai", "country": "UAE"},
        {"code": "IST", "name": "Istanbul Airport",
            "city": "Istanbul", "country": "Turkey"},
        {"code": "JFK", "name": "John F. Kennedy International",
            "city": "New York", "country": "USA"},
        {"code": "LHR", "name": "Heathrow Airport",
            "city": "London", "country": "UK"},
        {"code": "CDG", "name": "Charles de Gaulle",
            "city": "Paris", "country": "France"},
    ]

    airports = []
    for ap_data in airports_data:
        airport = Airport(**ap_data)
        airports.append(airport)
        db.add(airport)

    db.commit()

    # 2. Airplanes with seat configurations
    seat_configs = [
        {
            "model": "Boeing 737",
            "total_seats": 150,
            "config": {"rows": 25, "seats_per_row": [3, 3], "extra_legroom_rows": [1, 2, 24, 25]}
        },
        {
            "model": "Airbus A320",
            "total_seats": 180,
            "config": {"rows": 30, "seats_per_row": [3, 3], "extra_legroom_rows": [1, 2, 29, 30]}
        },
        {
            "model": "Boeing 777",
            "total_seats": 300,
            "config": {"rows": 50, "seats_per_row": [3, 4, 3], "extra_legroom_rows": [1, 2, 49, 50]}
        },
    ]

    airplanes = []
    for ap_data in seat_configs:
        airplane = Airplane(
            model=ap_data["model"],
            total_seats=ap_data["total_seats"],
            seat_config=json.dumps(ap_data["config"])
        )
        airplanes.append(airplane)
        db.add(airplane)

    db.commit()

    # 3. Users
    # Staff user
    admin = User(
        email="admin@airline.com",
        hashed_password=hash_password("admin123"),
        full_name="Admin Staff",
        role=UserRole.STAFF
    )
    db.add(admin)

    # Passenger user
    passenger = User(
        email="passenger@example.com",
        hashed_password=hash_password("pass123"),
        full_name="John Doe",
        role=UserRole.PASSENGER
    )
    db.add(passenger)

    db.commit()

    # 4. Flights
    now = datetime.utcnow()
    flights_data = [
        {
            "flight_number": "SU-101",
            "origin": airports[0],  # FRU
            "destination": airports[1],  # DXB
            "airplane": airplanes[0],
            "departure_time": now + timedelta(days=1, hours=10),
            "arrival_time": now + timedelta(days=1, hours=14),
            "base_price": 250.0,
            "gate": "A12",
            "terminal": "1"
        },
        {
            "flight_number": "SU-102",
            "origin": airports[1],  # DXB
            "destination": airports[2],  # IST
            "airplane": airplanes[1],
            "departure_time": now + timedelta(days=2, hours=8),
            "arrival_time": now + timedelta(days=2, hours=11),
            "base_price": 180.0,
            "gate": "B5",
            "terminal": "2"
        },
        {
            "flight_number": "SU-201",
            "origin": airports[2],  # IST
            "destination": airports[3],  # JFK
            "airplane": airplanes[2],
            "departure_time": now + timedelta(days=3, hours=15),
            "arrival_time": now + timedelta(days=3, hours=23),
            "base_price": 650.0,
            "gate": "C8",
            "terminal": "1"
        },
        {
            "flight_number": "SU-301",
            "origin": airports[0],  # FRU
            "destination": airports[4],  # LHR
            "airplane": airplanes[0],
            "departure_time": now + timedelta(days=5, hours=12),
            "arrival_time": now + timedelta(days=5, hours=18),
            "base_price": 420.0,
            "gate": "A15",
            "terminal": "1"
        },
    ]

    for flight_data in flights_data:
        flight = Flight(
            flight_number=flight_data["flight_number"],
            origin_id=flight_data["origin"].id,
            destination_id=flight_data["destination"].id,
            airplane_id=flight_data["airplane"].id,
            departure_time=flight_data["departure_time"],
            arrival_time=flight_data["arrival_time"],
            base_price=flight_data["base_price"],
            status=FlightStatus.SCHEDULED,
            gate=flight_data.get("gate"),
            terminal=flight_data.get("terminal")
        )
        db.add(flight)

    db.commit()

    # Generate seats for all flights
    from app.services.seat_service import generate_seats_for_flight
    all_flights = db.query(Flight).all()
    for flight in all_flights:
        generate_seats_for_flight(db, flight)

    print("✅ Database seeded successfully!")
    print("📧 Staff credentials: admin@airline.com / admin123")
    print("📧 Passenger credentials: passenger@example.com / pass123")


if __name__ == "__main__":
    seed_data()
