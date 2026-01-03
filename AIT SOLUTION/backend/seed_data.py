from sqlmodel import Session, select
from datetime import datetime, timedelta, timezone
from app.database import engine, create_db_and_tables
from app.models import User, UserRole, UserStatus, Airport, Airplane, Flight, SeatTemplate, Booking, BookingStatus, Ticket, SeatClass
from app.core.security import get_password_hash

def seed_everything():
    print("🧹 Wiping and Initializing database...")
    from sqlmodel import SQLModel
    SQLModel.metadata.drop_all(engine)
    create_db_and_tables()
    
    with Session(engine) as session:
        print("🌱 Starting fresh data seeding...")

        # 1. Create Staff
        staff = User(
            email="staff1@ait.com",
            hashed_password=get_password_hash("Staff123!"),
            role=UserRole.STAFF,
            status=UserStatus.ACTIVE
        )
        session.add(staff)
        
        # 2. Create Admin
        admin = User(
            email="admin@ait.com",
            hashed_password=get_password_hash("Admin123!"),
            role=UserRole.ADMIN,
            status=UserStatus.ACTIVE
        )
        session.add(admin)

        # 3. Create Passenger
        passenger = User(
            email="passenger@ait.com",
            hashed_password=get_password_hash("Pass123!"),
            role=UserRole.PASSENGER,
            status=UserStatus.ACTIVE
        )
        session.add(passenger)
        session.commit()
        session.refresh(staff)

        # 4. Create Airports
        airports = [
            Airport(code="ALA", name="Almaty International Airport", city="Almaty", country="Kazakhstan", timezone="UTC+5"),
            Airport(code="NQZ", name="Astana International Airport", city="Astana", country="Kazakhstan", timezone="UTC+5"),
            Airport(code="IST", name="Istanbul Airport", city="Istanbul", country="Turkey", timezone="UTC+3"),
            Airport(code="KZN", name="Kazan Airport", city="Kazan", country="Russia", timezone="UTC+3"),
            Airport(code="SVO", name="Sheremetyevo Airport", city="Moscow", country="Russia", timezone="UTC+3"),
        ]
        session.add_all(airports)
        session.commit()

        # 5. Create Airplane
        plane = Airplane(
            model="Boeing 737",
            registration="UP-B3701",
            manufacturer="Boeing",
            total_seats=60,
            economy_seats=54,
            business_seats=6,
            rows_count=10,
            seats_per_row=6,
            owner_id=staff.id
        )
        session.add(plane)
        session.commit()
        session.refresh(plane)

        # 6. Create Seats for the plane based on its capacity
        print(f"  -> Creating {plane.total_seats} seats for plane {plane.registration}")
        seat_letters = ["A", "B", "C", "D", "E", "F"]
        for row in range(1, plane.rows_count + 1):
            for i in range(plane.seats_per_row):
                letter = seat_letters[i % len(seat_letters)]
                seq = (row - 1) * plane.seats_per_row + i
                seat_class = SeatClass.BUSINESS if seq < plane.business_seats else SeatClass.ECONOMY
                seat = SeatTemplate(
                    airplane_id=plane.id,
                    row_number=row,
                    seat_letter=letter,
                    seat_class=seat_class
                )
                session.add(seat)
        session.commit()

        # 7. Create Flights
        flights_to_add = [
            Flight(
                flight_number="KZ101",
                departure_airport_id=airports[0].id,
                arrival_airport_id=airports[1].id,
                airplane_id=plane.id,
                base_price=50.0,
                scheduled_departure=datetime.now(timezone.utc) + timedelta(hours=12),  # Через 12 часов - можно check-in
                scheduled_arrival=datetime.now(timezone.utc) + timedelta(hours=14),  # +2 часа полёт
                owner_id=staff.id,
                status="scheduled",
                check_in_opens=datetime.now(timezone.utc),
                check_in_closes=datetime.now(timezone.utc) + timedelta(hours=11),  # Закрывается за час до вылета
                gate_departure="A1",
                gate_arrival="B2"
            ),
            Flight(
                flight_number="SU202",
                departure_airport_id=airports[3].id,
                arrival_airport_id=airports[4].id,
                airplane_id=plane.id,
                base_price=75.0,
                scheduled_departure=datetime.now(timezone.utc) + timedelta(hours=18),  # Через 18 часов - можно check-in
                scheduled_arrival=datetime.now(timezone.utc) + timedelta(hours=19, minutes=30),  # +1.5 часа полёт
                owner_id=staff.id,
                status="scheduled",
                check_in_opens=datetime.now(timezone.utc),
                check_in_closes=datetime.now(timezone.utc) + timedelta(hours=17),  # Закрывается за час до вылета
                gate_departure="C3",
                gate_arrival="D4"
            )
        ]
        session.add_all(flights_to_add)
        session.commit()

        # 8. Create a test booking to occupy one seat
        test_booking = Booking(
            flight_id=flights_to_add[0].id,
            user_id=passenger.id,
            status=BookingStatus.PAID,
            total_price=50.0,
            passengers_count=1,
            booking_reference="REF-KZ101-TEST"
        )
        session.add(test_booking)
        session.commit()
        session.refresh(test_booking)

        # Occupy the very first seat (1A)
        first_seat = session.exec(select(SeatTemplate).where(SeatTemplate.airplane_id == plane.id)).first()
        test_ticket = Ticket(
            booking_id=test_booking.id,
            passenger_id=passenger.id,
            seat_id=first_seat.id,
            ticket_number=f"TK-{test_booking.id}-001"
        )
        session.add(test_ticket)
        session.commit()

        print(f"✅ Seeding complete!")
        print(f"   Staff: staff1@ait.com / Staff123!")
        print(f"   Admin: admin@ait.com / Admin123!")
        print(f"   Passenger: passenger@ait.com / Pass123!")
        print(f"   Flights: KZ101 and SU202 (Kazan -> Moscow)")
        print(f"   Note: Seat {first_seat.seat_letter}{first_seat.row_number} is occupied on flight KZ101.")

if __name__ == "__main__":
    seed_everything()
