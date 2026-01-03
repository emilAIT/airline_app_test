from sqlmodel import Session, create_engine, select, SQLModel
from datetime import datetime, timedelta, date
import random

from app.core.config import settings
from app.core.security import get_password_hash
from app.models import (
    User, UserRole, PassengerProfile,
    Airport, Airplane, SeatTemplate, SeatCategory,
    Flight, FlightSeat, FlightSeatStatus, FlightStatus,
    Booking, BookingStatus, BookingSeat,
    Ticket,
    Payment, PaymentMethod, PaymentStatus,
    CheckIn, BoardingPass,
    SeatHold,
    Announcement, AnnouncementType,
)

engine = create_engine(
    str(settings.SQLALCHEMY_DATABASE_URI),
    connect_args={"check_same_thread": False},
)


def init_db(session: Session) -> None:
    SQLModel.metadata.create_all(engine)

    # ==================================================
    # INITIAL STAFF USER
    # ==================================================
    staff_user = session.exec(
        select(User).where(User.email == settings.FIRST_SUPERUSER)
    ).first()

    if not staff_user:
        staff_user = User(
            email=settings.FIRST_SUPERUSER,
            full_name="Initial Admin",
            hashed_password=get_password_hash(settings.FIRST_SUPERUSER_PASSWORD),
            role=UserRole.STAFF,
            is_active=True,
        )
        session.add(staff_user)
        session.commit()
        session.refresh(staff_user)
        print(f"Created initial staff user: {staff_user.email} id={staff_user.id}")

    # ==================================================
    # AIRPORT SEED DATA
    # ==================================================
    existing_airport = session.exec(select(Airport)).first()
    if not existing_airport:
        airports = [
            Airport(code="IST", name="Istanbul Airport", city="Istanbul", country="Turkey"),
            Airport(code="LHR", name="Heathrow Airport", city="London", country="United Kingdom"),
            Airport(code="JFK", name="John F. Kennedy International Airport", city="New York", country="United States"),
            Airport(code="CDG", name="Charles de Gaulle Airport", city="Paris", country="France"),
            Airport(code="FRA", name="Frankfurt Airport", city="Frankfurt", country="Germany"),
        ]
        session.add_all(airports)
        session.commit()
        print(f"Created {len(airports)} airports")

    # ==================================================
    # AIRPLANES + SEAT TEMPLATES
    # ==================================================
    existing_airplane = session.exec(select(Airplane)).first()
    if not existing_airplane:
        airplanes_data = [
            {"model": "Boeing 737-800", "total_seats": 162, "rows": 27, "seats_per_row": ["A", "B", "C", "D", "E", "F"]},
            {"model": "Airbus A320", "total_seats": 180, "rows": 30, "seats_per_row": ["A", "B", "C", "D", "E", "F"]},
            {"model": "Boeing 777-300ER", "total_seats": 365, "rows": 42, "seats_per_row": ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K"]},
            {"model": "Airbus A350", "total_seats": 325, "rows": 40, "seats_per_row": ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K"]},
        ]

        airplanes = []
        for ap_data in airplanes_data:
            airplane = Airplane(model=ap_data["model"], total_seats=ap_data["total_seats"])
            session.add(airplane)
            session.flush()

            seat_templates = []
            for row in range(1, ap_data["rows"] + 1):
                for seat_label in ap_data["seats_per_row"]:
                    category = SeatCategory.EXTRA_LEGROOM if row <= 3 else SeatCategory.STANDARD
                    seat_templates.append(
                        SeatTemplate(
                            airplane_id=airplane.id,
                            row=row,
                            seat_label=seat_label,
                            category=category,
                        )
                    )
            session.add_all(seat_templates)
            airplanes.append(airplane)

        session.commit()
        print(f"Created {len(airplanes)} airplanes with seat templates")

    # ==================================================
    # FLIGHTS + FLIGHT SEATS
    # ==================================================
    existing_flight = session.exec(select(Flight)).first()
    if not existing_flight:
        airports = session.exec(select(Airport)).all()
        airplanes = session.exec(select(Airplane)).all()

        if not airports or not airplanes:
            print("Warning: Cannot create flights - airports or airplanes not found")
            return

        flights = []
        flight_number_counter = 100

        routes = [
            ("IST", "LHR"), ("LHR", "IST"),
            ("IST", "JFK"), ("JFK", "IST"),
            ("LHR", "CDG"), ("CDG", "LHR"),
            ("CDG", "FRA"), ("FRA", "CDG"),
            ("IST", "FRA"), ("FRA", "IST"),
        ]

        base_date = datetime(2025, 1, 2, 0, 0, 0)

        for day_offset in range(7):
            current_date = base_date + timedelta(days=day_offset)

            for origin_code, dest_code in routes:
                origin_airport = next((a for a in airports if a.code == origin_code), None)
                dest_airport = next((a for a in airports if a.code == dest_code), None)
                if not origin_airport or not dest_airport:
                    continue

                departure_hour = random.randint(6, 22)
                departure_minute = random.choice([0, 15, 30, 45])
                departure_time = current_date.replace(hour=departure_hour, minute=departure_minute)

                flight_duration_hours = random.randint(2, 8)
                arrival_time = departure_time + timedelta(hours=flight_duration_hours)

                airplane = random.choice(airplanes)
                gate = f"{random.choice(['A', 'B', 'C', 'D'])}{random.randint(1, 50)}"
                terminal = random.choice(["1", "2", "3"])

                flight = Flight(
                    flight_number=f"AA{flight_number_counter}",
                    origin_airport_id=origin_airport.id,
                    destination_airport_id=dest_airport.id,
                    departure_time=departure_time,
                    arrival_time=arrival_time,
                    status=FlightStatus.SCHEDULED,
                    gate=gate,
                    terminal=terminal,
                    airplane_id=airplane.id,
                )
                session.add(flight)
                session.flush()

                seat_templates = session.exec(
                    select(SeatTemplate).where(SeatTemplate.airplane_id == airplane.id)
                ).all()

                flight_seats = []
                for template in seat_templates:
                    base_price = 200 if template.category == SeatCategory.EXTRA_LEGROOM else 150
                    row_multiplier = 1.0 + (template.row / 100.0)
                    price = int(base_price * row_multiplier)

                    status = FlightSeatStatus.BOOKED if random.random() < 0.1 else FlightSeatStatus.AVAILABLE

                    flight_seats.append(
                        FlightSeat(
                            flight_id=flight.id,
                            row=template.row,
                            seat_label=template.seat_label,
                            category=template.category,
                            price=price,
                            status=status,
                        )
                    )

                session.add_all(flight_seats)
                flights.append(flight)
                flight_number_counter += 1

        session.commit()
        print(f"Created {len(flights)} flights with seats for January 2-9, 2025")

    # ==================================================
    # INITIAL PASSENGER USER + PROFILE
    # ==================================================
    passenger = session.exec(
        select(User).where(User.email == settings.PASSENGER_EMAIL)
    ).first()

    if not passenger:
        passenger = User(
            email=settings.PASSENGER_EMAIL,
            full_name=settings.PASSENGER_FULL_NAME,
            hashed_password=get_password_hash(settings.PASSENGER_PASSWORD),
            role=UserRole.PASSENGER,
            is_active=True,
        )
        session.add(passenger)
        session.flush()

    existing_profile = session.exec(
        select(PassengerProfile).where(PassengerProfile.user_id == passenger.id)
    ).first()

    if not existing_profile:
        dob = date.fromisoformat(settings.PASSENGER_DOB)
        profile = PassengerProfile(
            user_id=passenger.id,
            phone_number=settings.PASSENGER_PHONE,
            passport_number=settings.PASSENGER_PASSPORT,
            nationality=settings.PASSENGER_NATIONALITY,
            date_of_birth=dob,
        )
        session.add(profile)

    session.commit()
    session.refresh(passenger)
    print(f"Seed passenger: {passenger.email} id={passenger.id}")

    # ==================================================
    # PASSENGER FLOW DATA (BOOKING, TICKETS, PAYMENT, CHECKIN, ETC.)
    # ==================================================
    flight = session.exec(select(Flight).limit(1)).first()
    if not flight:
        print("No flights found; cannot seed passenger bookings")
        return

    booking = session.exec(
        select(Booking).where(Booking.user_id == passenger.id)
    ).first()

    if not booking:
        booking = Booking(
            user_id=passenger.id,
            flight_id=flight.id,
            pnr=f"PNR{passenger.id[:6].upper()}",
            status=BookingStatus.CONFIRMED,
        )
        session.add(booking)
        session.flush()

        seats = session.exec(
            select(FlightSeat)
            .where(FlightSeat.flight_id == flight.id)
            .where(FlightSeat.status == FlightSeatStatus.AVAILABLE)
            .limit(2)
        ).all()

        if not seats:
            print("No available seats found; cannot seed booking seats/tickets")
            session.rollback()
            return

        for idx, seat in enumerate(seats, start=1):
            seat.status = FlightSeatStatus.BOOKED
            session.add(seat)

            session.add(
                BookingSeat(
                    booking_id=booking.id,
                    flight_seat_id=seat.id,
                )
            )

            session.add(
                Ticket(
                    booking_id=booking.id,
                    flight_seat_id=seat.id,
                    passenger_name=passenger.full_name or f"Passenger {idx}",
                    seat_number=f"{seat.row}{seat.seat_label}",
                    ticket_number=f"TKT-{booking.pnr}-{idx}",
                )
            )

        session.add(
            Payment(
                booking_id=booking.id,
                method=PaymentMethod.CARD,
                status=PaymentStatus.PAID,
                idempotency_key=f"idem-{booking.pnr}",
            )
        )

        session.commit()
        session.refresh(booking)
        print(f"Seed booking created: id={booking.id} pnr={booking.pnr}")

    # check-in + boarding pass for one ticket
    ticket = session.exec(
        select(Ticket).where(Ticket.booking_id == booking.id).limit(1)
    ).first()

    if ticket:
        existing_checkin = session.exec(
            select(CheckIn).where(CheckIn.ticket_id == ticket.id)
        ).first()

        if not existing_checkin:
            checkin = CheckIn(ticket_id=ticket.id)
            session.add(checkin)
            session.flush()

            session.add(
                BoardingPass(
                    checkin_id=checkin.id,
                    seat_number=ticket.seat_number,
                    gate="A12",
                    boarding_group="1",
                    qr_code=f"QR-{ticket.ticket_number}",
                )
            )
            session.commit()
            print(f"Seed checkin+boarding pass created for ticket={ticket.ticket_number}")

    # seat hold (optional)
    free_seat = session.exec(
        select(FlightSeat)
        .where(FlightSeat.flight_id == flight.id)
        .where(FlightSeat.status == FlightSeatStatus.AVAILABLE)
        .limit(1)
    ).first()

    if free_seat:
        existing_hold = session.exec(
            select(SeatHold).where(SeatHold.flight_seat_id == free_seat.id)
        ).first()

        if not existing_hold:
            session.add(
                SeatHold(
                    flight_id=flight.id,
                    flight_seat_id=free_seat.id,
                    expires_at=datetime.utcnow() + timedelta(minutes=30),
                )
            )
            session.commit()
            print("Seed seat hold created")

    # announcement (optional)
    existing_announcement = session.exec(select(Announcement).limit(1)).first()
    if not existing_announcement:
        session.add(
            Announcement(
                flight_id=flight.id,
                type=AnnouncementType.GENERAL,
                title="Welcome on board",
                message="Seeded announcement for frontend testing.",
                created_by_user_id=staff_user.id,
            )
        )
        session.commit()
        print("Seed announcement created")
