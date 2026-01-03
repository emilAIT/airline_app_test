"""Seed script (exam requirements).

Seeds an exam-aligned dataset:
    - Airports / Flights / Seats
    - Bookings + Passengers + Tickets
    - Payments + Announcements

This script is designed to be safe to re-run (idempotent) and also supports
fully resetting the database for a clean demo dataset.
"""

from __future__ import annotations

import argparse
import random
from datetime import date, datetime, timedelta, timezone

from app.core.security import hash_password
from app.database import Base, SessionLocal, engine, init_db
from app.models.announcement import Announcement
from app.models.airport import Airport
from app.models.booking import Booking
from app.models.booking_passenger import BookingPassenger
from app.models.flight import Flight
from app.models.payment import Payment
from app.models.seat import Seat
from app.models.ticket import Ticket
from app.models.user import User
from app.services.id_generator import generate_ticket_number


def reset_db() -> None:
    """Drop and recreate all tables (SQLite dev/demo use)."""
    import app.models  # noqa: F401
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def _utcnow_minute() -> datetime:
    # Store UTC as naive datetime in DB (project convention), but avoid deprecated utcnow().
    return datetime.now(timezone.utc).replace(second=0, microsecond=0, tzinfo=None)


# Kyrgyzstan (Bishkek) timezone: UTC+6, no DST.
KG_OFFSET = timedelta(hours=6)


def _utc_to_kg(dt_utc: datetime) -> datetime:
    return dt_utc + KG_OFFSET


def _kg_to_utc(dt_kg: datetime) -> datetime:
    return dt_kg - KG_OFFSET


def seed_data(*, reset: bool, large: bool, flights_target: int) -> None:
    if reset:
        reset_db()
        print("Database reset")
    else:
        init_db()
        print("Database initialized")

    rnd = random.Random(42)
    random.seed(42)

    # Seed auth (staff + passenger) + airports/flights/seats + exam tables
    db = SessionLocal()
    try:
        # Users: create if missing (idempotent)
        staff = db.query(User).filter(User.email == "staff@zaku.kz").first()
        if not staff:
            staff = User(
                email="staff@zaku.kz",
                hashed_password=hash_password("staff123"),
                role="STAFF",
                is_active=True,
            )
            db.add(staff)

        passenger = db.query(User).filter(User.email == "passenger@zaku.kz").first()
        if not passenger:
            passenger = User(
                email="passenger@zaku.kz",
                hashed_password=hash_password("passenger123"),
                role="PASSENGER",
                is_active=True,
            )
            db.add(passenger)

        # Convenience demo passenger account (for the mobile app)
        zara = db.query(User).filter(User.email == "zara@gmail.com").first()
        if not zara:
            zara = User(
                email="zara@gmail.com",
                hashed_password=hash_password("zara123"),
                role="PASSENGER",
                is_active=True,
            )
            db.add(zara)

        db.commit()
        db.refresh(staff)
        db.refresh(passenger)

        # Airports
        if large:
            airport_specs = [
                ("ALA", "Almaty International Airport", "Almaty"),
                ("NQZ", "Nursultan Nazarbayev International Airport", "Astana"),
                ("DXB", "Dubai International Airport", "Dubai"),
                ("IST", "Istanbul Airport", "Istanbul"),
                ("TAS", "Tashkent International Airport", "Tashkent"),
                ("FRU", "Manas International Airport", "Bishkek"),
                ("CIT", "Shymkent International Airport", "Shymkent"),
                ("SVO", "Sheremetyevo International Airport", "Moscow"),
                ("DOH", "Hamad International Airport", "Doha"),
                ("DEL", "Indira Gandhi International Airport", "Delhi"),
                ("BKK", "Suvarnabhumi Airport", "Bangkok"),
                ("SIN", "Changi Airport", "Singapore"),
            ]
        else:
            airport_specs = [
                ("ALA", "Almaty International Airport", "Almaty"),
                ("NQZ", "Nursultan Nazarbayev International Airport", "Astana"),
                ("DXB", "Dubai International Airport", "Dubai"),
            ]
        airports: list[Airport] = []
        for code, name, city in airport_specs:
            existing = db.query(Airport).filter(Airport.code == code).first()
            if existing:
                airports.append(existing)
                continue
            a = Airport(code=code, name=name, city=city)
            db.add(a)
            airports.append(a)
        db.commit()
        for a in airports:
            db.refresh(a)

        by_code = {a.code: a for a in airports}

        now_utc = _utcnow_minute()
        now_kg = _utc_to_kg(now_utc)

        # Routes (duration in minutes)
        preferred_routes: list[tuple[str, str, int]] = [
            ("ALA", "NQZ", 90), ("NQZ", "ALA", 90),
            ("ALA", "DXB", 240), ("DXB", "ALA", 240),
            ("NQZ", "DXB", 300), ("DXB", "NQZ", 300),
        ]

        # For large mode: allow any airport pair
        airport_codes = [a.code for a in airports]
        all_pairs: list[tuple[str, str]] = [(o, d) for o in airport_codes for d in airport_codes if o != d]

        existing_fnums = {
            f for (f,) in db.query(Flight.flight_number).all() if isinstance(f, str) and f
        }
        next_num = 1000
        def next_flight_number() -> str:
            nonlocal next_num
            while True:
                cand = f"ZK{next_num}"
                next_num += 1
                if cand not in existing_fnums:
                    existing_fnums.add(cand)
                    return cand

        # Flights
        # Ensure there are enough future flights; if rerun, top up to flights_target.
        future_count = db.query(Flight).filter(Flight.departure_time >= now_utc).count()
        remaining = max(0, flights_target - future_count) if large else 0

        flights_spec: list[tuple[str, str, str, datetime, int, float, str]] = []

        def add_flight(o: str, d: str, dep: datetime, duration_min: int, *, force: bool = False) -> None:
            nonlocal remaining
            if not large:
                return
            if remaining <= 0 and not force:
                return
            if o not in by_code or d not in by_code or o == d:
                return
            price = round(12000.0 + duration_min * 120 + rnd.uniform(-4000, 4000), 2)
            flights_spec.append((next_flight_number(), o, d, dep, duration_min, price, "SCHEDULED"))
            if remaining > 0 and not force:
                remaining -= 1

        if large:
            # 1) Ensure some flights in near-future window in Bishkek time.
            # Generate in KG local time then convert to UTC for storage.
            quick_departures_kg = [now_kg + timedelta(hours=h) for h in (3, 4, 5, 6, 7)]
            for i, dep in enumerate(quick_departures_kg):
                o, d, duration_min = preferred_routes[i % len(preferred_routes)]
                add_flight(o, d, _kg_to_utc(dep), duration_min)

            # 1b) Explicit test flight: Bishkek (FRU) -> Dubai (DXB) around 17:00 Bishkek time.
            if 'FRU' in by_code and 'DXB' in by_code:
                target_kg = now_kg.replace(hour=17, minute=0)
                if target_kg <= now_kg:
                    # If it's already past 17:00 KG today, schedule a bit later (still today/soon).
                    target_kg = now_kg + timedelta(hours=2)

                target_utc = _kg_to_utc(target_kg)

                # Add only if we don't already have a similar flight in KG "today".
                start_kg = target_kg.replace(hour=0, minute=0, second=0, microsecond=0)
                end_kg = start_kg + timedelta(days=1)
                start_utc = _kg_to_utc(start_kg)
                end_utc = _kg_to_utc(end_kg)
                exists = (
                    db.query(Flight)
                    .filter(Flight.departure_time >= start_utc)
                    .filter(Flight.departure_time < end_utc)
                    .filter(Flight.origin_id == by_code['FRU'].id)
                    .filter(Flight.destination_id == by_code['DXB'].id)
                    .first()
                )
                if not exists:
                    add_flight('FRU', 'DXB', target_utc, 240, force=True)

            # 2) Coverage: make sure ALA has flights to/from every other airport in next 4 days.
            ala = "ALA" if "ALA" in by_code else airport_codes[0]
            cover_start_kg = now_kg + timedelta(hours=8)
            for idx, code in enumerate(airport_codes):
                if code == ala:
                    continue
                dur_out = rnd.randint(60, 360)
                dur_back = rnd.randint(60, 360)
                day_offset = idx % 4
                dep_out_kg = (cover_start_kg + timedelta(days=day_offset)).replace(minute=0) + timedelta(hours=idx % 6)
                dep_back_kg = dep_out_kg + timedelta(hours=3)
                add_flight(ala, code, _kg_to_utc(dep_out_kg), dur_out)
                add_flight(code, ala, _kg_to_utc(dep_back_kg), dur_back)

            # 3) Fill the rest across the next 14 days.
            days_span = 14
            i = 0
            while remaining > 0:
                o, d = all_pairs[(i * 7) % len(all_pairs)]
                duration_min = next((m for ro, rd, m in preferred_routes if ro == o and rd == d), None)
                if duration_min is None:
                    duration_min = rnd.randint(60, 360)
                day_offset = (i // 8) % days_span
                # Schedule departures during the KG local day (starting 06:00 KG).
                base_day_kg = (now_kg + timedelta(days=day_offset)).replace(hour=6, minute=0)
                dep_kg = base_day_kg + timedelta(minutes=90 * (i % 8))
                if dep_kg <= now_kg:
                    dep_kg = now_kg + timedelta(minutes=120 + 15 * (i % 8))
                add_flight(o, d, _kg_to_utc(dep_kg), duration_min)
                i += 1
        else:
            # Small mode: ensure the 3-airport mesh for next 4 days at least once.
            bundle_end = now_utc + timedelta(days=4)
            already_seeded = (
                db.query(Flight)
                .filter(Flight.departure_time >= now_utc)
                .filter(Flight.departure_time < bundle_end)
                .filter(Flight.origin_id.in_([by_code["ALA"].id, by_code["NQZ"].id, by_code["DXB"].id]))
                .filter(Flight.destination_id.in_([by_code["ALA"].id, by_code["NQZ"].id, by_code["DXB"].id]))
                .count()
            )
            if already_seeded == 0:
                near_future_start_kg = now_kg + timedelta(hours=6)
                for day_offset in range(0, 4):
                    base_departure_kg = near_future_start_kg if day_offset == 0 else (now_kg + timedelta(days=day_offset)).replace(hour=9, minute=0)
                    for idx, (origin_code, dest_code, duration_min) in enumerate(preferred_routes):
                        dep_kg = base_departure_kg + timedelta(minutes=60 * idx)
                        if dep_kg <= now_kg:
                            dep_kg = now_kg + timedelta(minutes=90 + (15 * idx))
                        dep = _kg_to_utc(dep_kg)
                        price = round(12000.0 + (duration_min * 140) + rnd.uniform(-2500, 2500), 2)
                        flights_spec.append((next_flight_number(), origin_code, dest_code, dep, duration_min, price, "SCHEDULED"))

        flights: list[Flight] = []
        if flights_spec:
            for fnum, origin_code, dest_code, dep, duration_min, price, status in flights_spec:
                arr = dep + timedelta(minutes=duration_min)
                terminal = rnd.choice(["T1", "T2"])
                gate = f"{rnd.choice(['A','B','C'])}{rnd.randint(1, 30)}"
                f = Flight(
                    flight_number=fnum,
                    origin_id=by_code[origin_code].id,
                    destination_id=by_code[dest_code].id,
                    departure_time=dep,
                    arrival_time=arr,
                    price=price,
                    status=status,
                    terminal=terminal,
                    gate=gate,
                )
                db.add(f)
                flights.append(f)

            db.commit()
            for f in flights:
                db.refresh(f)

        seat_letters = ["A", "B", "C", "D", "E", "F"]
        extra_rows = {1, 2, 3}
        total_rows = 20

        # If this run didn't create new flights, reuse existing upcoming flights so
        # the rest of the script (announcements/bookings) can still work.
        if not flights:
            flights = (
                db.query(Flight)
                .filter(Flight.departure_time >= now_utc)
                .order_by(Flight.departure_time.asc())
                .all()
            )

        def ensure_seat_map(f: Flight) -> None:
            existing_seats = db.query(Seat).filter(Seat.flight_id == f.id).count()
            if existing_seats > 0:
                return

            seats: list[Seat] = []
            all_codes: list[str] = []
            for row in range(1, total_rows + 1):
                for letter in seat_letters:
                    code = f"{row}{letter}"
                    all_codes.append(code)
                    if row in extra_rows:
                        seat_class = "EXTRA_LEGROOM"
                        markup = 0.25
                    else:
                        seat_class = "STANDARD"
                        markup = 0.0
                    seats.append(
                        Seat(
                            flight_id=f.id,
                            code=code,
                            seat_class=seat_class,
                            is_occupied=False,
                            price_markup=markup,
                        )
                    )

            protected = {"1A", "1B", "1C", "1D"}
            candidates = [c for c in all_codes if c not in protected]
            occupied = set(rnd.sample(candidates, 5))
            for s in seats:
                if s.code in occupied:
                    s.is_occupied = True

            db.add_all(seats)

        for flight in flights:
            ensure_seat_map(flight)

        db.commit()
        print("Seeded airports, flights, and seat maps.")

        # --- Announcements (linked to flights) ---
        # Create a couple announcements for the first two flights
        if flights:
            def ensure_announcement(*, flight_id: int, title: str, message: str) -> None:
                exists = (
                    db.query(Announcement)
                    .filter(Announcement.flight_id == flight_id)
                    .filter(Announcement.title == title)
                    .first()
                )
                if exists:
                    return
                db.add(
                    Announcement(
                        flight_id=flight_id,
                        created_by=staff.id,
                        title=title,
                        message=message,
                    )
                )

            ensure_announcement(
                flight_id=flights[0].id,
                title="Gate change",
                message="Gate changed to B12. Please proceed to the new gate.",
            )
            ensure_announcement(
                flight_id=flights[0].id,
                title="Delay",
                message="Departure delayed by 30 minutes due to operational reasons.",
            )
            if len(flights) > 1:
                ensure_announcement(
                    flight_id=flights[1].id,
                    title="Boarding",
                    message="Boarding has started. Please have your documents ready.",
                )

            db.commit()

        # --- Bookings / Passengers / Tickets / Payments ---
        if not flights:
            print("⚠️  No flights available to seed bookings/check-in demo.")
            return

        # Pick a flight for demo booking/check-in: prefer departure within 2..10 hours.
        demo_flight = (
            db.query(Flight)
            .filter(Flight.departure_time >= (now_utc + timedelta(hours=2)))
            .filter(Flight.departure_time <= (now_utc + timedelta(hours=10)))
            .order_by(Flight.departure_time.asc())
            .first()
        )
        flight = demo_flight or flights[0]

        def pick_free_seats(f: Flight, n: int) -> list[Seat]:
            return (
                db.query(Seat)
                .filter(Seat.flight_id == f.id)
                .filter(Seat.is_occupied == False)  # noqa: E712
                .order_by(Seat.code.asc())
                .limit(n)
                .all()
            )

        # Booking 1: CONFIRMED (has tickets + successful payment)
        seed_pnr1 = "SEED01"  # 6 chars, stable across reruns
        booking1 = db.query(Booking).filter(Booking.pnr_code == seed_pnr1).first()
        if not booking1:
            booking1 = Booking(
                pnr_code=seed_pnr1,
                user_id=passenger.id,
                flight_id=flight.id,
                total_amount=float(flight.price) * 2,
                status="CONFIRMED",
            )
            db.add(booking1)
            db.flush()

        # Ensure passengers/tickets exist for booking1
        existing_passengers = db.query(BookingPassenger).filter(BookingPassenger.booking_id == booking1.id).all()
        existing_tickets = db.query(Ticket).filter(Ticket.booking_id == booking1.id).all()
        if len(existing_passengers) < 2 or len(existing_tickets) < 2:
            free_seats = pick_free_seats(flight, 3)
            if len(free_seats) < 2:
                raise RuntimeError("Not enough free seats to seed bookings")

            seat1, seat2 = free_seats[0], free_seats[1]

            bp1 = db.query(BookingPassenger).filter(BookingPassenger.booking_id == booking1.id).filter(BookingPassenger.seat_number == seat1.code).first()
            if not bp1:
                bp1 = BookingPassenger(
                    booking_id=booking1.id,
                    flight_id=flight.id,
                    first_name="Aruzhan",
                    last_name="Khan",
                    seat_number=seat1.code,
                    passport_number="P1234567",
                    nationality="KZ",
                    date_of_birth=date(1999, 5, 20),
                )
                db.add(bp1)

            bp2 = db.query(BookingPassenger).filter(BookingPassenger.booking_id == booking1.id).filter(BookingPassenger.seat_number == seat2.code).first()
            if not bp2:
                bp2 = BookingPassenger(
                    booking_id=booking1.id,
                    flight_id=flight.id,
                    first_name="Dias",
                    last_name="Nurgali",
                    seat_number=seat2.code,
                    passport_number="P7654321",
                    nationality="KZ",
                    date_of_birth=date(2001, 11, 3),
                )
                db.add(bp2)

            db.flush()

            def ensure_ticket(*, booking: Booking, passenger: BookingPassenger, seat: Seat, ticket_number: str) -> None:
                exists = db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first()
                if exists:
                    return
                already_for_seat = (
                    db.query(Ticket)
                    .filter(Ticket.flight_id == booking.flight_id)
                    .filter(Ticket.seat_number == seat.code)
                    .first()
                )
                if already_for_seat:
                    return
                db.add(
                    Ticket(
                        ticket_number=ticket_number,
                        booking_id=booking.id,
                        flight_id=booking.flight_id,
                        passenger_id=passenger.id,
                        seat_id=seat.id,
                        passenger_first_name=passenger.first_name,
                        passenger_last_name=passenger.last_name,
                        seat_number=seat.code,
                        price=float(booking.flight.price),
                    )
                )
                seat.is_occupied = True

            ensure_ticket(
                booking=booking1,
                passenger=bp1,
                seat=seat1,
                ticket_number="7840000000001",
            )
            ensure_ticket(
                booking=booking1,
                passenger=bp2,
                seat=seat2,
                ticket_number="7840000000002",
            )

        # Ensure a successful payment exists for booking1 (idempotent)
        pay_key_1 = "seed-SEED01-1"
        existing_payment_1 = db.query(Payment).filter(Payment.idempotency_key == pay_key_1).first()
        if not existing_payment_1:
            db.add(
                Payment(
                    booking_id=booking1.id,
                    idempotency_key=pay_key_1,
                    amount=booking1.total_amount,
                    status="PAID",
                    payment_method="MOCK_CARD",
                    processed_at=datetime.now(timezone.utc).replace(tzinfo=None),
                )
            )

        db.commit()

        # Booking 2: CREATED (demo unpaid booking)
        # NOTE: This does not create SeatHold rows, so it won't be payable via the app.
        flight2 = flights[1] if len(flights) > 1 else flights[0]
        seed_pnr2 = "SEED02"
        booking2 = db.query(Booking).filter(Booking.pnr_code == seed_pnr2).first()
        if not booking2:
            booking2 = Booking(
                pnr_code=seed_pnr2,
                user_id=passenger.id,
                flight_id=flight2.id,
                total_amount=float(flight2.price),
                status="CREATED",
            )
            db.add(booking2)
            db.flush()

        free_seat3 = pick_free_seats(flight2, 1)
        if free_seat3:
            seat3 = free_seat3[0]
            existing_bp3 = (
                db.query(BookingPassenger)
                .filter(BookingPassenger.booking_id == booking2.id)
                .filter(BookingPassenger.seat_number == seat3.code)
                .first()
            )
            if not existing_bp3:
                db.add(
                    BookingPassenger(
                        booking_id=booking2.id,
                        flight_id=flight2.id,
                        first_name="Amina",
                        last_name="Sadyk",
                        seat_number=seat3.code,
                        passport_number="P0001122",
                        nationality="KZ",
                        date_of_birth=date(2004, 2, 15),
                    )
                )

        db.commit()

        print("Seeded bookings, passengers, tickets, payments, and announcements.")
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed ZaKu exam database")
    parser.add_argument("--reset", action="store_true", help="Drop and recreate all tables before seeding")
    parser.add_argument("--large", action="store_true", help="Seed many airports and 100+ future flights")
    parser.add_argument("--flights", type=int, default=120, help="Target number of future flights (large mode)")
    args = parser.parse_args()

    seed_data(reset=bool(args.reset), large=bool(args.large), flights_target=int(args.flights))