"""
Seed data script - creates initial airports and staff users.
"""
from __future__ import annotations

from datetime import datetime, timedelta
import random
from typing import Iterable

from sqlalchemy.orm import Session

from app.database import SessionLocal, init_db
from app.repositories.airport import airport_repository
from app.repositories.user import user_repository
from app.core.security import hash_password
from app.models.airplane import Airplane
from app.models.airport import Airport
from app.models.flight import Flight


def seed_airports(db: Session):
    """Create airports (KZ + nearby regions) for richer testing."""
    airports_data = [
        # Kazakhstan
        {"code": "ALA", "name": "Almaty International Airport", "city": "Almaty", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "TSE", "name": "Nursultan Nazarbayev International Airport", "city": "Astana", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "CIT", "name": "Shymkent International Airport", "city": "Shymkent", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "KGF", "name": "Karaganda Airport", "city": "Karaganda", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "PWQ", "name": "Pavlodar Airport", "city": "Pavlodar", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "UKK", "name": "Oskemen Airport", "city": "Oskemen", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "GUW", "name": "Atyrau Airport", "city": "Atyrau", "country": "Kazakhstan", "timezone": "Asia/Atyrau"},
        {"code": "AKX", "name": "Aktobe Airport", "city": "Aktobe", "country": "Kazakhstan", "timezone": "Asia/Aqtobe"},
        {"code": "SCO", "name": "Aktau Airport", "city": "Aktau", "country": "Kazakhstan", "timezone": "Asia/Aqtau"},
        {"code": "DMB", "name": "Taraz Airport", "city": "Taraz", "country": "Kazakhstan", "timezone": "Asia/Almaty"},
        {"code": "KZO", "name": "Kyzylorda Airport", "city": "Kyzylorda", "country": "Kazakhstan", "timezone": "Asia/Qyzylorda"},
        # Kyrgyzstan
        {"code": "FRU", "name": "Manas International Airport", "city": "Bishkek", "country": "Kyrgyzstan", "timezone": "Asia/Bishkek"},
        {"code": "OSS", "name": "Osh International Airport", "city": "Osh", "country": "Kyrgyzstan", "timezone": "Asia/Bishkek"},
        # Uzbekistan
        {"code": "TAS", "name": "Islam Karimov Tashkent International Airport", "city": "Tashkent", "country": "Uzbekistan", "timezone": "Asia/Tashkent"},
        {"code": "SKD", "name": "Samarkand International Airport", "city": "Samarkand", "country": "Uzbekistan", "timezone": "Asia/Samarkand"},
        # Russia
        {"code": "SVO", "name": "Sheremetyevo International Airport", "city": "Moscow", "country": "Russia", "timezone": "Europe/Moscow"},
        {"code": "LED", "name": "Pulkovo Airport", "city": "Saint Petersburg", "country": "Russia", "timezone": "Europe/Moscow"},
        # Turkey / UAE
        {"code": "IST", "name": "Istanbul Airport", "city": "Istanbul", "country": "Turkey", "timezone": "Europe/Istanbul"},
        {"code": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "UAE", "timezone": "Asia/Dubai"},
    ]
    
    for data in airports_data:
        existing = airport_repository.get_by_code(db, data["code"])
        if not existing:
            airport_repository.create(db, **data)
            print(f"✈️  Created airport: {data['code']} - {data['city']} ({data['country']})")
    
    db.commit()


def seed_airplanes(db: Session):
    """Create a small fleet with different capacities for seat map testing."""
    airplanes_data = [
        {"registration_number": "ZK-A320-01", "model": "Airbus A320neo", "manufacturer": "Airbus", "total_seats": 180},
        {"registration_number": "ZK-A320-02", "model": "Airbus A320", "manufacturer": "Airbus", "total_seats": 168},
        {"registration_number": "ZK-B738-01", "model": "Boeing 737-800", "manufacturer": "Boeing", "total_seats": 189},
        {"registration_number": "ZK-B737-01", "model": "Boeing 737-700", "manufacturer": "Boeing", "total_seats": 144},
        {"registration_number": "ZK-E190-01", "model": "Embraer E190-E2", "manufacturer": "Embraer", "total_seats": 108},
        {"registration_number": "ZK-B773-01", "model": "Boeing 777-300ER", "manufacturer": "Boeing", "total_seats": 300},
    ]

    for data in airplanes_data:
        exists = db.query(Airplane).filter(Airplane.registration_number == data["registration_number"]).first()
        if exists:
            continue

        db.add(Airplane(**data))
        print(f"🛩️  Created airplane: {data['registration_number']} ({data['model']}, {data['total_seats']} seats)")

    db.commit()


def seed_staff_user(db: Session):
    """Create default staff user for testing."""
    email = "staff@zaku.kz"
    password = "staff123"

    if user_repository.get_by_email(db, email) is None:
        user_repository.create(
            db=db,
            email=email,
            hashed_password=hash_password(password),
            role="STAFF",
        )
        db.commit()
        print(f"👨‍✈️  Created staff user: {email} / {password}")


def seed_flights(
    db: Session,
    *,
    days: int = 60,
    flights_per_day: int = 40,
    start_day_offset: int = 1,
    random_seed: int = 42,
):
    """Create MANY sample flights for testing flight search.

    Goals:
    - Lots of flights across many airport pairs
    - Many departure dates (for date filter)
    - Deterministic generation (stable demos)
    """
    airports = db.query(Airport).all()
    airplanes = db.query(Airplane).all()
    
    if not airports or not airplanes:
        print("⚠️  Cannot create flights: missing airports or airplanes")
        return
    
    by_code = {a.code: a for a in airports}

    def has_airports(codes: Iterable[str]) -> bool:
        return all(c in by_code for c in codes)

    # Prefer realistic routes; fall back to random if some airports are missing.
    routes: list[tuple[str, str, int]] = []  # (from, to, duration_minutes)
    candidate_routes = [
        ("ALA", "TSE", 90), ("TSE", "ALA", 90),
        ("ALA", "CIT", 80), ("CIT", "ALA", 80),
        ("ALA", "GUW", 150), ("GUW", "ALA", 150),
        ("ALA", "SCO", 170), ("SCO", "ALA", 170),
        ("TSE", "KGF", 75), ("KGF", "TSE", 75),
        ("FRU", "OSS", 45), ("OSS", "FRU", 45),
        ("FRU", "ALA", 70), ("ALA", "FRU", 70),
        ("FRU", "TAS", 85), ("TAS", "FRU", 85),
        ("ALA", "IST", 320), ("IST", "ALA", 320),
        ("ALA", "DXB", 260), ("DXB", "ALA", 260),
        ("FRU", "SVO", 270), ("SVO", "FRU", 270),
        ("TSE", "LED", 290), ("LED", "TSE", 290),
    ]
    for o, d, mins in candidate_routes:
        if has_airports([o, d]):
            routes.append((o, d, mins))

    if not routes:
        print("⚠️  No preferred routes found; using random route generation")
        routes = [(a.code, b.code, random.randint(60, 180)) for a in airports for b in airports if a.id != b.id][:20]

    rnd = random.Random(random_seed)

    # Create flights for the next N days starting tomorrow by default.
    start_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    start_date = start_date + timedelta(days=max(0, start_day_offset))
    departure_hours = [6, 8, 10, 12, 14, 16, 18, 20]
    departure_minutes = [0, 15, 30, 45]

    # Find next available numeric suffix for ZK flight numbers
    existing_nums = set()
    for fnum, in db.query(Flight.flight_number).all():
        if isinstance(fnum, str) and fnum.startswith("ZK"):
            n = int(''.join([c for c in fnum[2:] if c.isdigit()]) or 0)
            if n:
                existing_nums.add(n)
    counter = max(existing_nums) + 1 if existing_nums else 100

    def next_flight_number() -> str:
        nonlocal counter
        while True:
            candidate = f"ZK{counter}"  # <= 10 chars
            counter += 1
            if not db.query(Flight).filter(Flight.flight_number == candidate).first():
                return candidate

    print(f"🛫 Seeding flights for {days} days, {flights_per_day}/day...")
    created = 0
    for day in range(0, days):
        current_day = start_date + timedelta(days=day)

        # N flights per day (rotating through routes)
        for i in range(flights_per_day):
            o_code, d_code, duration = routes[(day * 12 + i) % len(routes)]
            origin = by_code[o_code]
            dest = by_code[d_code]
            airplane = rnd.choice(airplanes)

            hour = departure_hours[(day + i) % len(departure_hours)]
            minute = departure_minutes[(day * 3 + i) % len(departure_minutes)]
            departure = current_day.replace(hour=hour, minute=minute)
            arrival = departure + timedelta(minutes=duration)

            # Simple price model by international vs domestic
            if origin.country != dest.country:
                base_price = 24000.0 + (duration * 35)
            else:
                base_price = 12000.0 + (duration * 25)

            # Small variation so lists aren't all identical.
            base_price = round(base_price + rnd.uniform(-1500, 1500), 2)

            flight = Flight(
                flight_number=next_flight_number(),
                airplane_id=airplane.id,
                origin_airport_id=origin.id,
                destination_airport_id=dest.id,
                departure_time=departure,
                arrival_time=arrival,
                base_price=base_price,
                status="SCHEDULED",
            )
            db.add(flight)
            created += 1

    db.commit()
    print(f"Flights seeded! Created {created} flights.")


if __name__ == "__main__":
    init_db()
    db = SessionLocal()
    try:
        seed_airports(db)
        seed_airplanes(db)
        seed_staff_user(db)
        seed_flights(db)
    finally:
        db.close()
