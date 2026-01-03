from datetime import datetime, timedelta
import random
from app.db.session import SessionLocal
from app.models.user import User, UserRole
from app.models.passenger import PassengerProfile
from app.models.airport import Airport
from app.models.airplane import Airplane, AirplaneStatus
from app.models.flight import Flight, FlightStatus
from app.models.booking import Booking, BookingStatus, Ticket, SeatHold
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.announcement import Announcement, AnnouncementType
from app.utils.security import get_password_hash
from zoneinfo import ZoneInfo

def populate():
    db = SessionLocal()
    print("Starting population...")

    # 1. Ensure Airports (Match seed_data.py exactly)
    airports_data = [
        {"code": "IST", "name": "Istanbul Airport", "city": "Istanbul", "country": "Turkey"},
        {"code": "JFK", "name": "John F. Kennedy International Airport", "city": "New York", "country": "USA"},
        {"code": "LHR", "name": "London Heathrow Airport", "city": "London", "country": "UK"},
        {"code": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "UAE"},
    ]

    airports = {}
    for data in airports_data:
        ap = db.query(Airport).filter(Airport.code == data["code"]).first()
        if not ap:
            ap = Airport(**data)
            db.add(ap)
            print(f"Created airport: {data['code']}")
        else:
            print(f"Airport exists: {data['code']}")
        airports[data["code"]] = ap
    db.commit()
    # Refresh map
    for code in airports:
        airports[code] = db.query(Airport).filter(Airport.code == code).first()

    # Use Kyrgyz time for consistent relative offsets
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None).replace(second=0, microsecond=0)

    # 2. Get Flights (Created by seed_data.py)
    # We use these existing flights for bookings and announcements to keep the data clean
    flight_list = db.query(Flight).order_by(Flight.departure_time).all()
    if len(flight_list) < 5:
        print("⚠ Not enough flights found! Please run seed_data.py first.")
        # Fallback to creating a few if absolutely necessary, but we expect seed_data to run first
        return

    f_boarding = flight_list[0]
    f_boarding.status = FlightStatus.BOARDING
    
    f_delayed = flight_list[1]
    f_delayed.status = FlightStatus.DELAYED
    
    f_departed = flight_list[2]
    f_departed.status = FlightStatus.DEPARTED
    
    f_landed = flight_list[3]
    f_landed.status = FlightStatus.LANDED
    
    f_future = flight_list[4]

    db.commit()

    db.commit()

    # 4. Create Users (Passengers)
    passengers_data = [
        {"email": "alice@example.com", "name": "Alice Walker"},
        {"email": "bob@example.com", "name": "Bob Builder"},
    ]
    
    created_users = []
    for p in passengers_data:
        u = db.query(User).filter(User.email == p["email"]).first()
        if not u:
            u = User(
                email=p["email"],
                hashed_password=get_password_hash("password123"),
                role=UserRole.PASSENGER,
                is_active=True,
                is_approved=True
            )
            db.add(u)
            db.flush()
            
            prof = PassengerProfile(
                user_id=u.id,
                full_name=p["name"],
                phone_number=f"+1{random.randint(2000000000, 9999999999)}",
                passport_number=f"P{random.randint(10000, 99999)}",
                nationality="USA",
                date_of_birth=datetime(1990, 1, 1).date()
            )
            db.add(prof)
            print(f"✓ Created user: {p['email']}")
        created_users.append(u)
    
    db.commit()

    # 5. Create Bookings & Announcements
    def create_confirmed_booking(user, flight, seat):
        existing = db.query(Booking).filter(Booking.user_id == user.id, Booking.flight_id == flight.id).first()
        if existing: return existing
        
        b = Booking(
            pnr=f"PNR{random.randint(1000,9999)}",
            user_id=user.id,
            flight_id=flight.id,
            status=BookingStatus.CONFIRMED,
            created_at=now - timedelta(days=1)
        )
        db.add(b)
        db.flush()
        
        prof = db.query(PassengerProfile).filter(PassengerProfile.user_id == user.id).first()
        if prof:
            db.add(Ticket(
                ticket_number=f"TKT{random.randint(1000000, 9999999)}",
                booking_id=b.id,
                passenger_profile_id=prof.id,
                seat_number=seat,
                price=flight.price
            ))
            
            db.add(Payment(
                booking_id=b.id,
                amount=flight.price,
                method=PaymentMethod.CARD,
                status=PaymentStatus.PAID,
                transaction_id=f"TXN{random.randint(100000,999999)}",
                created_at=now - timedelta(days=1)
            ))
        return b

    # Create various bookings
    create_confirmed_booking(created_users[0], f_boarding, "1A")
    create_confirmed_booking(created_users[1], f_delayed, "10C")
    create_confirmed_booking(created_users[0], f_departed, "5B")
    create_confirmed_booking(created_users[1], f_landed, "15F")

    # 8. Add Pending Bookings (HOLD status)
    # Active HOLD
    if not db.query(Booking).filter(Booking.pnr == "HOLD10").first():
        db.add(Booking(pnr="HOLD10", user_id=created_users[0].id, flight_id=f_future.id, status=BookingStatus.HOLD, created_at=now - timedelta(minutes=2)))
    
    # Expired HOLD
    if not db.query(Booking).filter(Booking.pnr == "EXPIRED").first():
        db.add(Booking(pnr="EXPIRED", user_id=created_users[1].id, flight_id=f_future.id, status=BookingStatus.HOLD, created_at=now - timedelta(minutes=15)))

    # 9. Create Announcements (Relative to now)
    announcements_data = [
        # Flight Specific
        {
            "flight_id": f_boarding.id,
            "type": AnnouncementType.BOARDING_STARTED,
            "title": "Boarding Started",
            "message": f"Boarding has started for flight {f_boarding.flight_number}. Please proceed to Gate {f_boarding.gate}.",
            "created_at": now - timedelta(minutes=5)
        },
        {
            "flight_id": f_delayed.id,
            "type": AnnouncementType.DELAY,
            "title": "Flight Delayed",
            "message": f"Flight {f_delayed.flight_number} is delayed. New departure time: {f_delayed.departure_time.strftime('%H:%M')}.",
            "created_at": now - timedelta(minutes=10)
        },
        {
            "flight_id": f_departed.id,
            "type": AnnouncementType.GENERAL,
            "title": "Flight Departed",
            "message": f"Flight {f_departed.flight_number} has departed.",
            "created_at": now - timedelta(minutes=65)
        },
        {
            "flight_id": f_landed.id,
            "type": AnnouncementType.GENERAL,
            "title": "Flight Landed",
            "message": f"Flight {f_landed.flight_number} has landed safely.",
            "created_at": now - timedelta(minutes=25)
        },
        # General Announcements
        {
            "flight_id": None,
            "type": AnnouncementType.GENERAL,
            "title": "🎄 Seasonal Sale",
            "message": "Holiday Sale – Get up to 20% off selected routes! Book your tickets early to save more.",
            "created_at": now - timedelta(hours=2)
        },
        {
            "flight_id": None,
            "type": AnnouncementType.GENERAL,
            "title": "📱 New App Update",
            "message": "Check out our all-new real-time flight tracking feature in the latest version of the mobile app!",
            "created_at": now - timedelta(hours=5)
        },
        {
            "flight_id": None,
            "type": AnnouncementType.GENERAL,
            "title": "🌍 Sustainable Travel",
            "message": "Learn more about our green initiative and how we are committed to reducing our carbon footprint.",
            "created_at": now - timedelta(days=1)
        },
        {
            "flight_id": None,
            "type": AnnouncementType.GENERAL,
            "title": "💎 Loyalty Rewards",
            "message": "Earn double miles on all flights to Europe this month! Sign up for our Loyalty Program today.",
            "created_at": now - timedelta(days=2)
        },
        {
            "flight_id": None,
            "type": AnnouncementType.GENERAL,
            "title": "🌩️ Weather Warning",
            "message": "Heavy storms are predicted in the Northeast area. Please check your flight status regularly for potential updates.",
            "created_at": now - timedelta(hours=1)
        }
    ]
    
    for a_data in announcements_data:
        # Avoid duplicates by title and type
        existing_ann = db.query(Announcement).filter(
            Announcement.title == a_data["title"],
            Announcement.type == a_data["type"],
            Announcement.flight_id == a_data["flight_id"]
        ).first()
        if not existing_ann:
            db.add(Announcement(**a_data))
            print(f"✓ Created announcement: {a_data['title']}")
        else:
            print(f"Announcement exists: {a_data['title']}")

    db.commit()
    print("✓ Population complete with statuses and announcements.")
    db.close()

if __name__ == "__main__":
    # Create tables
    from app.db.base import Base
    from app.db.session import engine
    Base.metadata.create_all(bind=engine)
    
    populate()
