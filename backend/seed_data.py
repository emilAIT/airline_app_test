"""
Seed database with initial data
"""
from datetime import datetime, timedelta
from app.database import SessionLocal, engine, Base
from app.models import User, Airport, Airplane, SeatTemplate, Flight, PassengerProfile
from app.enums import UserRole, FlightStatus, SeatCategory
from app.auth import get_password_hash

# Drop and recreate all tables
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    print("Seeding database...")
    
    # Create staff user
    staff_user = db.query(User).filter(User.email == "staff@airline.com").first()
    if not staff_user:
        staff_user = User(
            email="staff@airline.com",
            hashed_password=get_password_hash("staff123"),
            role=UserRole.STAFF
        )
        db.add(staff_user)
        print("✓ Created staff user: staff@airline.com / staff123")
    
    # Create test passenger
    passenger_user = db.query(User).filter(User.email == "passenger@test.com").first()
    if not passenger_user:
        passenger_user = User(
            email="passenger@test.com",
            hashed_password=get_password_hash("pass123"),
            role=UserRole.PASSENGER
        )
        db.add(passenger_user)
        db.flush()
        
        # Create passenger profile
        profile = PassengerProfile(
            user_id=passenger_user.id,
            full_name="John Doe",
            phone_number="+1234567890",
            passport_number="AB1234567",
            nationality="USA",
            date_of_birth=datetime(1990, 1, 1),
            is_complete=True
        )
        db.add(profile)
        print("✓ Created test passenger: passenger@test.com / pass123")
    
    # Create airports
    airports_data = [
        {"code": "IST", "name": "Istanbul Airport", "city": "Istanbul", "country": "Turkey"},
        {"code": "ADB", "name": "Izmir Adnan Menderes Airport", "city": "Izmir", "country": "Turkey"},
        {"code": "ESB", "name": "Esenboga Airport", "city": "Ankara", "country": "Turkey"},
        {"code": "LHR", "name": "London Heathrow", "city": "London", "country": "United Kingdom"},
        {"code": "CDG", "name": "Charles de Gaulle", "city": "Paris", "country": "France"},
        {"code": "FRA", "name": "Frankfurt Airport", "city": "Frankfurt", "country": "Germany"},
        {"code": "AMS", "name": "Amsterdam Schiphol", "city": "Amsterdam", "country": "Netherlands"},
        {"code": "JFK", "name": "John F. Kennedy International", "city": "New York", "country": "USA"},
        {"code": "DXB", "name": "Dubai International", "city": "Dubai", "country": "UAE"},
        {"code": "SIN", "name": "Singapore Changi", "city": "Singapore", "country": "Singapore"},
    ]
    
    for airport_data in airports_data:
        existing = db.query(Airport).filter(Airport.code == airport_data["code"]).first()
        if not existing:
            airport = Airport(**airport_data)
            db.add(airport)
    
    db.commit()
    print(f"✓ Created {len(airports_data)} airports")
    
    # Create airplanes with seat templates
    airplane1 = db.query(Airplane).filter(Airplane.registration == "TC-JRO").first()
    if not airplane1:
        airplane1 = Airplane(
            model="Boeing 737-800",
            registration="TC-JRO",
            total_seats=180
        )
        db.add(airplane1)
        db.flush()
        
        # Create seat template: 30 rows, 6 seats per row (A-F)
        # Rows 1-5 and exits (12-13) are extra legroom
        for row in range(1, 31):
            for seat_label in ['A', 'B', 'C', 'D', 'E', 'F']:
                category = SeatCategory.EXTRA_LEGROOM if (row <= 5 or row in [12, 13]) else SeatCategory.STANDARD
                seat = SeatTemplate(
                    airplane_id=airplane1.id,
                    row_number=row,
                    seat_label=seat_label,
                    category=category
                )
                db.add(seat)
        
        print(f"✓ Created airplane: {airplane1.model} ({airplane1.registration})")
    
    airplane2 = db.query(Airplane).filter(Airplane.registration == "TC-LJA").first()
    if not airplane2:
        airplane2 = Airplane(
            model="Airbus A321",
            registration="TC-LJA",
            total_seats=200
        )
        db.add(airplane2)
        db.flush()
        
        # Create seat template: 33 rows, 6 seats per row (A-F), some 7 seats (adding G)
        for row in range(1, 34):
            seats_in_row = ['A', 'B', 'C', 'D', 'E', 'F']
            category = SeatCategory.EXTRA_LEGROOM if row <= 3 else SeatCategory.STANDARD
            
            for seat_label in seats_in_row:
                seat = SeatTemplate(
                    airplane_id=airplane2.id,
                    row_number=row,
                    seat_label=seat_label,
                    category=category
                )
                db.add(seat)
        
        print(f"✓ Created airplane: {airplane2.model} ({airplane2.registration})")
    
    db.commit()
    
    # Get airport IDs
    ist = db.query(Airport).filter(Airport.code == "IST").first()
    lhr = db.query(Airport).filter(Airport.code == "LHR").first()
    cdg = db.query(Airport).filter(Airport.code == "CDG").first()
    jfk = db.query(Airport).filter(Airport.code == "JFK").first()
    dxb = db.query(Airport).filter(Airport.code == "DXB").first()
    adb = db.query(Airport).filter(Airport.code == "ADB").first()
    
    # Create flights
    base_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    flights_data = [
        {
            "flight_number": "TK1980",
            "airplane_id": airplane1.id,
            "origin_airport_id": ist.id,
            "destination_airport_id": lhr.id,
            "departure_time": base_date + timedelta(days=1, hours=10),
            "arrival_time": base_date + timedelta(days=1, hours=14, minutes=30),
            "base_price": 250.00,
            "gate": "A12",
            "terminal": "1",
            "boarding_time": base_date + timedelta(days=1, hours=9, minutes=30),
        },
        {
            "flight_number": "TK1981",
            "airplane_id": airplane1.id,
            "origin_airport_id": lhr.id,
            "destination_airport_id": ist.id,
            "departure_time": base_date + timedelta(days=1, hours=20),
            "arrival_time": base_date + timedelta(days=2, hours=1, minutes=30),
            "base_price": 260.00,
            "gate": "B5",
            "terminal": "2",
            "boarding_time": base_date + timedelta(days=1, hours=19, minutes=30),
        },
        {
            "flight_number": "TK1824",
            "airplane_id": airplane2.id,
            "origin_airport_id": ist.id,
            "destination_airport_id": cdg.id,
            "departure_time": base_date + timedelta(days=2, hours=8),
            "arrival_time": base_date + timedelta(days=2, hours=12),
            "base_price": 220.00,
            "gate": "C7",
            "terminal": "1",
            "boarding_time": base_date + timedelta(days=2, hours=7, minutes=30),
        },
        {
            "flight_number": "TK1",
            "airplane_id": airplane2.id,
            "origin_airport_id": ist.id,
            "destination_airport_id": jfk.id,
            "departure_time": base_date + timedelta(days=3, hours=13),
            "arrival_time": base_date + timedelta(days=3, hours=17),
            "base_price": 850.00,
            "gate": "D15",
            "terminal": "1",
            "boarding_time": base_date + timedelta(days=3, hours=12, minutes=30),
        },
        {
            "flight_number": "TK123",
            "airplane_id": airplane1.id,
            "origin_airport_id": ist.id,
            "destination_airport_id": dxb.id,
            "departure_time": base_date + timedelta(days=1, hours=15),
            "arrival_time": base_date + timedelta(days=1, hours=21),
            "base_price": 450.00,
            "gate": "E20",
            "terminal": "1",
            "boarding_time": base_date + timedelta(days=1, hours=14, minutes=30),
        },
        {
            "flight_number": "TK2310",
            "airplane_id": airplane1.id,
            "origin_airport_id": adb.id,
            "destination_airport_id": ist.id,
            "departure_time": base_date + timedelta(days=1, hours=9),
            "arrival_time": base_date + timedelta(days=1, hours=10, minutes=15),
            "base_price": 80.00,
            "gate": "F3",
            "terminal": "2",
            "boarding_time": base_date + timedelta(days=1, hours=8, minutes=30),
        },
    ]
    
    for flight_data in flights_data:
        existing = db.query(Flight).filter(Flight.flight_number == flight_data["flight_number"]).first()
        if not existing:
            flight = Flight(**flight_data, status=FlightStatus.SCHEDULED)
            db.add(flight)
    
    db.commit()
    print(f"✓ Created {len(flights_data)} flights")
    
    print("\n✓ Database seeded successfully!")
    print("\nCredentials:")
    print("  Staff:     staff@airline.com / staff123")
    print("  Passenger: passenger@test.com / pass123")
    
except Exception as e:
    print(f"Error seeding database: {e}")
    db.rollback()
    raise
finally:
    db.close()

