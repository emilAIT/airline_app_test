import logging
# Monkey patch bcrypt to work with Python 3.13 by truncating passwords to 72 bytes
try:
    import bcrypt
    original_hashpw = bcrypt.hashpw

    def patched_hashpw(password, salt):
        if isinstance(password, str):
            password = password.encode('utf-8')
        if len(password) > 72:
            password = password[:72]
        return original_hashpw(password, salt)
    bcrypt.hashpw = patched_hashpw
except ImportError:
    pass

from app.auth.auth_handler import hash_password, verify_password
from app.models.media import Photo
from app.models.all_models import (
    Announcement, Flight, AnnouncementType, AnnouncementPriority,
    Airport, Airplane, FlightStatus, User, UserRole, Booking, BookingStatus,
    Ticket, Payment, PaymentStatus, PaymentMethod, Notification,
    PassengerProfile, CheckIn, Seat, SeatCategory, CancellationPolicy, SeatHold
)
from app.database import SessionLocal, engine, Base
from app.services.seat_service import generate_seats_for_flight, mark_seat_unavailable
from app.services.booking_service import generate_pnr, generate_ticket_number
from datetime import datetime, timedelta, date, timezone
import os
import sys
import uuid
import json

# Add the parent directory to sys.path to allow imports from app
sys.path.append(os.path.join(os.path.dirname(__file__)))


def reset_db():
    """Completely drop and recreate all tables for a clean start"""
    print("=" * 60)
    print("Resetting database...")
    print("=" * 60)
    # Drop all tables and recreate them to ensure new schema
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    print("✅ Database reset complete.")
    print()


def seed_data():
    """Seed comprehensive realistic data for testing"""
    db = SessionLocal()
    try:
        print("=" * 60)
        print("Seeding comprehensive test data...")
        print("=" * 60)

        # === USERS ===
        print("\n📝 Creating users...")

        # Test Passenger Account
        test_user = User(
            email="test@eldiyar.com",
            hashed_password=hash_password("password123"),
            full_name="ELDIK Tester",
            role=UserRole.PASSENGER
        )

        # Admin/Staff Account
        admin_user = User(
            email="admin@eldiyar.com",
            hashed_password=hash_password("password123"),
            full_name="Admin User",
            role=UserRole.STAFF
        )

        db.add_all([test_user, admin_user])
        db.flush()  # Flush to get IDs

        # Verify passwords work
        if not verify_password("password123", test_user.hashed_password):
            raise Exception(
                "Password hashing verification failed for test user!")
        if not verify_password("password123", admin_user.hashed_password):
            raise Exception(
                "Password hashing verification failed for admin user!")
        print(f"✅ Created user: {test_user.email} (ID: {test_user.id})")
        print(f"✅ Created user: {admin_user.email} (ID: {admin_user.id})")
        print(f"✅ Password hashing verified for both users")

        # === PASSENGER PROFILE (Required for bookings) ===
        print("\n👤 Creating passenger profile...")
        passenger_profile = PassengerProfile(
            user_id=test_user.id,
            passport_number="P12345678",
            phone_number="+996 555 123456",
            nationality="Kyrgyzstan",
            date_of_birth=date(1990, 5, 15)
        )
        db.add(passenger_profile)
        print("✅ Passenger profile created")

        # === AIRPORTS ===
        print("\n🛫 Creating airports...")
        airports = [
            Airport(code="FRU", name="Manas International Airport",
                    city="Bishkek", country="Kyrgyzstan"),
            Airport(code="IST", name="Istanbul Airport",
                    city="Istanbul", country="Turkey"),
            Airport(code="DXB", name="Dubai International Airport",
                    city="Dubai", country="UAE"),
            Airport(code="LHR", name="Heathrow Airport",
                    city="London", country="UK"),
            Airport(code="ALA", name="Almaty International Airport",
                    city="Almaty", country="Kazakhstan"),
            Airport(code="CDG", name="Charles de Gaulle Airport",
                    city="Paris", country="France"),
        ]
        db.add_all(airports)
        db.flush()
        print(f"✅ Created {len(airports)} airports")

        # === PHOTOS ===
        print("\n📸 Creating photos...")
        # Airport photos
        airport_photos = [
            Photo(url="fru_manas.webp", category="AIRPORT",
                  entity_type="airport", entity_id=airports[0].id),
            Photo(url="istanbul-airport.webp", category="AIRPORT",
                  entity_type="airport", entity_id=airports[1].id),
            Photo(url="dxb_dubai.jpg", category="AIRPORT",
                  entity_type="airport", entity_id=airports[2].id),
            Photo(url="LHR_London.webp", category="AIRPORT",
                  entity_type="airport", entity_id=airports[3].id),
            Photo(url="ALA_Almaty.jpg", category="AIRPORT",
                  entity_type="airport", entity_id=airports[4].id),
        ]

        # Destination photos
        destination_photos = [
            Photo(url="paris.webp", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="tokyo.avif", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="NewYork.webp", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="Barcelona.jpeg", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="London.avif", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="Singapore.avif", category="DESTINATION",
                  entity_type="city", is_active=True),
            Photo(url="Sydney.jpg", category="DESTINATION",
                  entity_type="city", is_active=True),
        ]

        db.add_all(airport_photos + destination_photos)
        print("✅ Photos created")

        # === AIRPLANES ===
        print("\n✈️ Creating airplanes...")
        plane1 = Airplane(model="Boeing 737 MAX", total_seats=180,
                          seat_config='{"rows":30, "layout":"3-3", "seats_per_row":[3,3]}')
        plane2 = Airplane(model="Airbus A320", total_seats=180,
                          seat_config='{"rows":30, "layout":"3-3", "seats_per_row":[3,3]}')
        db.add_all([plane1, plane2])
        db.flush()
        print("✅ Airplanes created")

        # === FLIGHTS ===
        print("\n🛫 Creating flights...")
        now = datetime.utcnow()
        now_utc = now.replace(tzinfo=timezone.utc)

        # Past flight (LANDED) - for past trip
        past_flight = Flight(
            flight_number="EA100",
            origin_id=airports[0].id,  # FRU
            destination_id=airports[1].id,  # IST
            airplane_id=plane1.id,
            departure_time=now_utc - timedelta(days=5, hours=10),
            arrival_time=now_utc - timedelta(days=5, hours=5),
            base_price=350.0,
            status=FlightStatus.LANDED,
            gate="A01",
            terminal="1"
        )

        # Future flights for upcoming trip and testing
        # Upcoming flight 1 - for upcoming confirmed trip
        upcoming_flight1 = Flight(
            flight_number="EA203",
            origin_id=airports[0].id,  # FRU
            destination_id=airports[1].id,  # IST
            airplane_id=plane1.id,
            departure_time=now_utc + timedelta(days=3, hours=8),
            arrival_time=now_utc + timedelta(days=3, hours=13),
            base_price=350.0,
            status=FlightStatus.SCHEDULED,
            gate="B12",
            terminal="1"
        )

        # Upcoming flight 2 - for pending payment
        upcoming_flight2 = Flight(
            flight_number="EA450",
            origin_id=airports[0].id,  # FRU
            destination_id=airports[2].id,  # DXB
            airplane_id=plane1.id,
            departure_time=now_utc + timedelta(days=7, hours=14),
            arrival_time=now_utc + timedelta(days=7, hours=18),
            base_price=420.0,
            status=FlightStatus.SCHEDULED,
            gate="C05",
            terminal="1"
        )

        # Flight 3 - BOARDING status (for admin dashboard)
        boarding_flight = Flight(
            flight_number="EA101",
            origin_id=airports[0].id,  # FRU
            destination_id=airports[3].id,  # LHR
            airplane_id=plane1.id,
            departure_time=now_utc + timedelta(minutes=45),
            arrival_time=now_utc + timedelta(hours=11),
            base_price=600.0,
            status=FlightStatus.BOARDING,
            gate="A03",
            terminal="1"
        )

        # Flight 4 - DELAYED status
        delayed_flight = Flight(
            flight_number="EA302",
            origin_id=airports[0].id,  # FRU
            destination_id=airports[4].id,  # ALA
            airplane_id=plane2.id,
            departure_time=now_utc + timedelta(hours=2),
            arrival_time=now_utc + timedelta(hours=3),
            base_price=200.0,
            status=FlightStatus.DELAYED,
            gate="C08",
            terminal="1"
        )

        # Flight 5 - More scheduled flights for variety
        scheduled_flight1 = Flight(
            flight_number="EA501",
            origin_id=airports[1].id,  # IST
            destination_id=airports[5].id,  # CDG
            airplane_id=plane2.id,
            departure_time=now_utc + timedelta(days=2, hours=10),
            arrival_time=now_utc + timedelta(days=2, hours=13),
            base_price=450.0,
            status=FlightStatus.SCHEDULED,
            gate="D12",
            terminal="2"
        )

        flights = [past_flight, upcoming_flight1, upcoming_flight2, boarding_flight,
                   delayed_flight, scheduled_flight1]
        db.add_all(flights)
        db.flush()
        print(f"✅ Created {len(flights)} flights")

        # Generate seats for all flights
        print("\n🪑 Generating seats for flights...")
        for flight in flights:
            generate_seats_for_flight(db, flight)
        print("✅ Seats generated for all flights")

        # === BOOKINGS FOR TEST USER ===
        print("\n🎫 Creating bookings for test user...")

        # 1. PAST TRIP: Completed (LANDED) flight with CONFIRMED booking
        print("  → Creating past trip (completed flight)...")
        past_booking = Booking(
            pnr="ELD100",
            user_id=test_user.id,
            flight_id=past_flight.id,
            status=BookingStatus.CONFIRMED,
            hold_until=None,  # No hold for confirmed bookings
            created_at=now_utc - timedelta(days=6)
        )
        db.add(past_booking)
        db.flush()

        # Create ticket for past booking
        past_ticket = Ticket(
            booking_id=past_booking.id,
            seat_number="12A",
            passenger_name="ELDIK Tester",
            ticket_number="TK10012345"
        )
        db.add(past_ticket)
        db.flush()

        # Mark seat as unavailable
        mark_seat_unavailable(db, past_flight.id, "12A")

        # Create payment for past booking
        past_payment = Payment(
            booking_id=past_booking.id,
            amount=350.0,
            currency="USD",
            method=PaymentMethod.CARD,
            status=PaymentStatus.PAID,
            transaction_id=f"TXN{str(uuid.uuid4())[:8].upper()}",
            created_at=now_utc - timedelta(days=6)
        )
        db.add(past_payment)
        print("    ✅ Past trip created (PNR: ELD100, Ticket: TK10012345)")

        # 2. UPCOMING TRIP: Future flight with CONFIRMED booking, seat, and payment
        print("  → Creating upcoming confirmed trip...")
        upcoming_booking = Booking(
            pnr="ELD777",
            user_id=test_user.id,
            flight_id=upcoming_flight1.id,
            status=BookingStatus.CONFIRMED,
            hold_until=None,
            created_at=now_utc - timedelta(days=2)
        )
        db.add(upcoming_booking)
        db.flush()

        # Create ticket with seat assignment
        upcoming_ticket = Ticket(
            booking_id=upcoming_booking.id,
            seat_number="15B",
            passenger_name="ELDIK Tester",
            ticket_number="TK12345678"
        )
        db.add(upcoming_ticket)
        db.flush()

        # Mark seat as unavailable
        mark_seat_unavailable(db, upcoming_flight1.id, "15B")

        # Create payment
        upcoming_payment = Payment(
            booking_id=upcoming_booking.id,
            amount=350.0,
            currency="USD",
            method=PaymentMethod.CARD,
            status=PaymentStatus.PAID,
            transaction_id=f"TXN{str(uuid.uuid4())[:8].upper()}",
            created_at=now_utc - timedelta(days=2)
        )
        db.add(upcoming_payment)
        print("    ✅ Upcoming trip created (PNR: ELD777, Ticket: TK12345678)")

        # 3. PENDING PAYMENT: Booking with CREATED status (5 minutes ago)
        print("  → Creating pending payment booking...")
        pending_hold_until = now_utc + \
            timedelta(minutes=5)  # 5 minutes remaining
        pending_booking = Booking(
            pnr="ELD888",
            user_id=test_user.id,
            flight_id=upcoming_flight2.id,
            status=BookingStatus.CREATED,
            hold_until=pending_hold_until,
            created_at=now_utc - timedelta(minutes=5)
        )
        db.add(pending_booking)
        db.flush()

        # Create ticket (seat will be held, not booked yet)
        pending_ticket = Ticket(
            booking_id=pending_booking.id,
            seat_number="8C",
            passenger_name="ELDIK Tester",
            ticket_number="TK88888888"
        )
        db.add(pending_ticket)
        db.flush()

        # Create seat hold for pending booking
        seat_hold = SeatHold(
            booking_id=pending_booking.id,
            flight_id=upcoming_flight2.id,
            seat_number="8C",
            held_until=pending_hold_until
        )
        db.add(seat_hold)
        print("    ✅ Pending payment booking created (PNR: ELD888, Ticket: TK88888888, expires in 5 min)")

        # === NOTIFICATIONS ===
        print("\n🔔 Creating notifications...")
        notifications = [
            Notification(
                user_id=test_user.id,
                message="Welcome to ELDIK AirLines! Check your upcoming trips in 'My Trips'.",
                is_read=False,
                created_at=now_utc - timedelta(hours=2)
            ),
            Notification(
                user_id=test_user.id,
                message=f"Gate changed for your flight EA203 to Istanbul. New gate: B12",
                is_read=False,
                created_at=now_utc - timedelta(minutes=30)
            ),
            Notification(
                user_id=test_user.id,
                message="Your payment for booking ELD888 is pending. Complete payment within 5 minutes.",
                is_read=False,
                created_at=now_utc - timedelta(minutes=5)
            ),
            Notification(
                user_id=test_user.id,
                message="Thank you for flying with ELDIK AirLines! Check-in for EA203 opens in 2 days.",
                is_read=True,
                created_at=now_utc - timedelta(days=1)
            ),
        ]
        db.add_all(notifications)
        print(f"✅ Created {len(notifications)} notifications")

        # === ANNOUNCEMENTS ===
        print("\n📢 Creating announcements...")

        # Global announcements by admin
        announcements = [
            # Global Welcome (by admin)
            Announcement(
                title="Welcome to ELDIK AirLines 2.0",
                message="Experience the new standard in aviation. Please check your flight status for the latest updates.",
                type=AnnouncementType.GENERAL,
                priority=AnnouncementPriority.LOW,
                created_at=now_utc - timedelta(hours=1),
                effective_from=now_utc - timedelta(hours=1),
                expires_at=now_utc + timedelta(days=1)
            ),

            # Security Reminder (Global, by admin)
            Announcement(
                title="Security Reminder",
                message="Please have your boarding pass and ID ready for security screening. Liquids > 100ml are not permitted.",
                type=AnnouncementType.SECURITY,
                priority=AnnouncementPriority.LOW,
                created_at=now_utc - timedelta(hours=2),
                effective_from=now_utc - timedelta(hours=2),
                expires_at=now_utc + timedelta(days=1)
            ),

            # Gate Change for Boarding Flight
            Announcement(
                flight_id=boarding_flight.id,
                title="Gate Change",
                message=f"Flight {boarding_flight.flight_number} to London: Departure gate has changed to **A03**. Please proceed immediately.",
                type=AnnouncementType.GATE_CHANGE,
                priority=AnnouncementPriority.HIGH,
                created_at=now_utc - timedelta(minutes=10),
                effective_from=now_utc - timedelta(minutes=10),
                expires_at=boarding_flight.departure_time
            ),

            # Boarding Soon
            Announcement(
                flight_id=boarding_flight.id,
                title="Boarding Starts Soon",
                message=f"Priority boarding for flight {boarding_flight.flight_number} will begin in 10 minutes at Gate A03.",
                type=AnnouncementType.BOARDING_SOON,
                priority=AnnouncementPriority.MEDIUM,
                created_at=now_utc - timedelta(minutes=5),
                effective_from=now_utc - timedelta(minutes=5),
                expires_at=boarding_flight.departure_time
            ),

            # Delay for Delayed Flight
            Announcement(
                flight_id=delayed_flight.id,
                title="Flight Delayed",
                message=f"Flight {delayed_flight.flight_number} to Almaty is delayed by 30 minutes due to late inbound aircraft.",
                type=AnnouncementType.DELAY,
                priority=AnnouncementPriority.MEDIUM,
                created_at=now_utc - timedelta(minutes=15),
                effective_from=now_utc - timedelta(minutes=15),
                expires_at=delayed_flight.departure_time
            ),

            # Check-in Reminder for Upcoming Flight
            Announcement(
                flight_id=upcoming_flight1.id,
                title="Check-in Open",
                message=f"Online check-in for flight {upcoming_flight1.flight_number} to Istanbul is now open. Save time at the airport!",
                type=AnnouncementType.CHECK_IN,
                priority=AnnouncementPriority.LOW,
                created_at=now_utc - timedelta(hours=1),
                effective_from=now_utc - timedelta(hours=1),
                expires_at=upcoming_flight1.departure_time -
                timedelta(minutes=60)
            ),
        ]
        db.add_all(announcements)
        print(f"✅ Created {len(announcements)} announcements")

        # === CANCELLATION POLICY ===
        print("\n📋 Creating cancellation policy...")
        cancellation_policy = CancellationPolicy(
            min_hours_before_departure=24,
            allow_card_refund=True,
            allow_apple_pay_refund=True,
            refund_fee_percent=0,
            is_active=True
        )
        db.add(cancellation_policy)
        print("✅ Cancellation policy created")

        # Commit everything
        db.commit()
        print("\n" + "=" * 60)
        print("✅ SEEDING COMPLETE!")
        print("=" * 60)
        print("\n📋 Summary:")
        print(f"  • Users: 2 (test@eldiyar.com, admin@eldiyar.com)")
        print(f"  • Password for both: password123")
        print(f"  • Airports: {len(airports)}")
        print(
            f"  • Flights: {len(flights)} (LANDED: 1, BOARDING: 1, DELAYED: 1, SCHEDULED: 3)")
        print(f"  • Bookings for test user: 3")
        print(f"    - Past trip (ELD100) - CONFIRMED, LANDED")
        print(f"    - Upcoming trip (ELD777) - CONFIRMED, SCHEDULED")
        print(f"    - Pending payment (ELD888) - CREATED, expires in 5 min")
        print(f"  • Notifications: {len(notifications)}")
        print(f"  • Announcements: {len(announcements)}")
        print("\n🎯 Test Credentials:")
        print("  Passenger: test@eldiyar.com / password123")
        print("  Staff: admin@eldiyar.com / password123")
        print("\n" + "=" * 60)

    except Exception as e:
        print(f"\n❌ Error seeding data: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    reset_db()
    seed_data()
