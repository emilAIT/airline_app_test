from typing import Any, Optional
import uuid

from sqlmodel import Session, select

from app.core.security import get_password_hash, verify_password
from datetime import date, datetime, timedelta
import random
import string

from app.models import (
    Flight,
    FlightCreate,
    FlightUpdate,
    FlightStatus,
    Airplane,
    AirplaneCreate,
    Airport,
    AirportCreate, 
    AirportUpdate, 
    User, 
    UserCreate, 
    UserUpdate,
    AirplaneUpdate,
    FlightSeat,
    SeatCategory,
    FlightSeatStatus,
    Booking,
    BookingCreate,
    BookingStatus,
    BookingSeat,
    Ticket,
    TicketCreate, 
    Payment,
    PaymentCreate,
    PaymentStatus,
    PaymentMethod, 
    SeatHold, 
    CheckIn, 
    BoardingPass,
    Announcement,
    AnnouncementCreate,
    AnnouncementUpdate,
    AnnouncementType,
    UserRole
)


def create_user(*, session: Session, user_create: UserCreate) -> User:
    db_obj = User.model_validate(
        user_create, update={"hashed_password": get_password_hash(user_create.password)}
    )
    session.add(db_obj)
    session.commit()
    session.refresh(db_obj)
    return db_obj


def update_user(*, session: Session, db_user: User, user_in: UserUpdate) -> Any:
    user_data = user_in.model_dump(exclude_unset=True)
    extra_data = {}
    if "password" in user_data:
        password = user_data["password"]
        hashed_password = get_password_hash(password)
        extra_data["hashed_password"] = hashed_password
    db_user.sqlmodel_update(user_data, update=extra_data)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def get_user_by_email(*, session: Session, email: str) -> User | None:
    statement = select(User).where(User.email == email)
    session_user = session.exec(statement).first()
    return session_user


def authenticate(*, session: Session, email: str, password: str) -> User | None:
    db_user = get_user_by_email(session=session, email=email)
    if not db_user:
        return None
    if not verify_password(password, db_user.hashed_password):
        return None
    return db_user


# =========================
# AIRPORT CRUD
# =========================

def create_airport(*, session: Session, airport_in: AirportCreate) -> Airport:
    airport = Airport.model_validate(airport_in)
    session.add(airport)
    session.commit()
    session.refresh(airport)
    return airport


def get_airports(*, session: Session) -> list[Airport]:
    statement = select(Airport)
    return session.exec(statement).all()


def get_airport(*, session: Session, airport_id: str) -> Airport | None:
    return session.get(Airport, airport_id)


def update_airport(
    *,
    session: Session,
    db_airport: Airport,
    airport_in: AirportUpdate,
) -> Airport:
    data = airport_in.model_dump(exclude_unset=True)
    db_airport.sqlmodel_update(data)
    session.commit()
    session.refresh(db_airport)
    return db_airport


def delete_airport(*, session: Session, db_airport: Airport) -> None:
    session.delete(db_airport)
    session.commit()


# =========================
# AIRPLANE CRUD
# =========================

def get_airplanes(*, session: Session) -> list[Airplane]:
    return session.exec(select(Airplane)).all()


def get_airplane(*, session: Session, airplane_id: str) -> Airplane | None:
    return session.get(Airplane, airplane_id)


def create_airplane(*, session: Session, airplane_in: AirplaneCreate) -> Airplane:
    airplane = Airplane.model_validate(airplane_in)
    session.add(airplane)
    session.commit()
    session.refresh(airplane)
    return airplane


def update_airplane(
    *,
    session: Session,
    db_airplane: Airplane,
    airplane_in: AirplaneUpdate,
) -> Airplane:
    data = airplane_in.model_dump(exclude_unset=True)
    db_airplane.sqlmodel_update(data)
    session.commit()
    session.refresh(db_airplane)
    return db_airplane


def delete_airplane(*, session: Session, db_airplane: Airplane) -> None:
    session.delete(db_airplane)
    session.commit()


# =========================
# FLIGHT CRUD
# =========================

def create_flight(*, session: Session, flight_in: FlightCreate) -> Flight:
    if flight_in.arrival_time <= flight_in.departure_time:
        raise ValueError("Arrival time must be after departure time")

    flight = Flight.model_validate(flight_in)
    session.add(flight)
    session.flush() 

    if flight.airplane_id:
        airplane = session.get(Airplane, flight.airplane_id)
        if not airplane:
            raise ValueError("Airplane not found")

        if not airplane.seat_templates:
            raise ValueError("Airplane has no seat templates")

        seats: list[FlightSeat] = []

        for template in airplane.seat_templates:
            price = (
                100
                if template.category == SeatCategory.STANDARD
                else 150
            )

            seats.append(
                FlightSeat(
                    flight_id=flight.id,
                    row=template.row,
                    seat_label=template.seat_label,
                    category=template.category,
                    price=price,
                    status=FlightSeatStatus.AVAILABLE,
                )
            )

        session.add_all(seats)

    session.commit()
    session.refresh(flight)
    return flight



def get_flight(*, session: Session, flight_id: str) -> Flight | None:
    return session.get(Flight, flight_id)


def get_flights(
    *,
    session: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[Flight]:
    statement = select(Flight).offset(skip).limit(limit)
    return session.exec(statement).all()


def update_flight(
    *,
    session: Session,
    db_flight: Flight,
    flight_in: FlightUpdate,
) -> Flight:
    old_status = db_flight.status
    data = flight_in.model_dump(exclude_unset=True)
    db_flight.sqlmodel_update(data)
    session.commit()
    session.refresh(db_flight)
    
    # Автоматическое создание announcement при изменении статуса рейса
    if flight_in.status is not None and flight_in.status != old_status:
        print(f"[FLIGHT_STATUS] Status changed from {old_status} to {flight_in.status} for flight_id={db_flight.id}, flight_number={db_flight.flight_number}")
        try:
            if flight_in.status == FlightStatus.CANCELLED:
                create_auto_announcement(
                    session=session,
                    flight_id=db_flight.id,
                    announcement_type=AnnouncementType.CANCELLATION,
                    title=f"Flight {db_flight.flight_number} Cancelled",
                    message=f"We regret to inform you that flight {db_flight.flight_number} has been cancelled. Please contact our support for rebooking options.",
                )
            elif flight_in.status == FlightStatus.DELAYED:
                create_auto_announcement(
                    session=session,
                    flight_id=db_flight.id,
                    announcement_type=AnnouncementType.DELAY,
                    title=f"Flight {db_flight.flight_number} Delayed",
                    message=f"Flight {db_flight.flight_number} has been delayed. Please check the updated departure time and arrive at the airport accordingly.",
                )
            elif flight_in.status == FlightStatus.BOARDING:
                create_auto_announcement(
                    session=session,
                    flight_id=db_flight.id,
                    announcement_type=AnnouncementType.BOARDING_STARTED,
                    title=f"Boarding Started - Flight {db_flight.flight_number}",
                    message=f"Boarding has started for flight {db_flight.flight_number}. Please proceed to the gate.",
                )
            print(f"[FLIGHT_STATUS] Successfully created announcement for flight status change")
        except Exception as e:
            # Не прерываем процесс, если announcement не создался
            print(f"[FLIGHT_STATUS] ERROR: Failed to create announcement for flight status change: {e}")
    
    return db_flight


def delete_flight(*, session: Session, db_flight: Flight) -> None:
    session.delete(db_flight)
    session.commit()


def search_flights(
    *,
    session: Session,
    origin_airport_id: str,
    destination_airport_id: str,
    departure_date_from: date,
    departure_date_to: Optional[date] = None,
) -> list[Flight]:
    print(f"CRUD search_flights: Searching flights")
    print(f"  - Origin Airport ID: {origin_airport_id}")
    print(f"  - Destination Airport ID: {destination_airport_id}")
    print(f"  - Departure Date From: {departure_date_from}")
    print(f"  - Departure Date To: {departure_date_to}")
    
    # If only one date is provided, use it as both start and end
    if departure_date_to is None:
        departure_date_to = departure_date_from
        print(f"  - Using single date search: {departure_date_from}")
    
    start_dt = datetime.combine(departure_date_from, datetime.min.time())
    end_dt = datetime.combine(departure_date_to, datetime.max.time())
    
    print(f"  - Search time range: {start_dt} to {end_dt}")

    statement = (
        select(Flight)
        .where(Flight.origin_airport_id == origin_airport_id)
        .where(Flight.destination_airport_id == destination_airport_id)
        .where(Flight.departure_time >= start_dt)
        .where(Flight.departure_time <= end_dt)
        .where(Flight.status != FlightStatus.CANCELLED)
    )

    flights = session.exec(statement).all()
    print(f"CRUD search_flights: Found {len(flights)} flights in database")
    
    if flights:
        print(f"  - First flight: {flights[0].flight_number} from {flights[0].departure_time}")

    return flights


# =========================
# SEAT HOLD CRUD
# =========================

HOLD_DURATION_MINUTES = 10


def cleanup_expired_seat_holds(*, session: Session) -> None:
    """
    Remove expired seat holds and free seats.
    """
    now = datetime.utcnow()

    expired_holds = session.exec(
        select(SeatHold).where(SeatHold.expires_at < now)
    ).all()

    for hold in expired_holds:
        # просто удаляем hold
        session.delete(hold)

    session.commit()


def is_seat_held(
    *,
    session: Session,
    flight_seat_id: str,
) -> bool:
    """
    Check if seat is currently held (not expired).
    """
    now = datetime.utcnow()

    hold = session.exec(
        select(SeatHold)
        .where(SeatHold.flight_seat_id == flight_seat_id)
        .where(SeatHold.expires_at > now)
    ).first()

    return hold is not None


def create_seat_hold(
    *,
    session: Session,
    flight_id: str,
    flight_seat_id: str,
) -> SeatHold:
    """
    Create seat hold for 10 minutes.
    """

    cleanup_expired_seat_holds(session=session)

    # double-hold protection
    existing_hold = session.exec(
        select(SeatHold)
        .where(SeatHold.flight_seat_id == flight_seat_id)
        .where(SeatHold.expires_at > datetime.utcnow())
    ).first()

    if existing_hold:
        raise ValueError("Seat is already held")

    expires_at = datetime.utcnow() + timedelta(minutes=HOLD_DURATION_MINUTES)

    hold = SeatHold(
        flight_id=flight_id,
        flight_seat_id=flight_seat_id,
        expires_at=expires_at,
    )

    session.add(hold)
    session.commit()
    session.refresh(hold)

    return hold


def release_seat_hold(
    *,
    session: Session,
    flight_seat_id: str,
) -> None:
    """
    Remove seat hold manually (e.g. after payment).
    """
    holds = session.exec(
        select(SeatHold)
        .where(SeatHold.flight_seat_id == flight_seat_id)
    ).all()

    for hold in holds:
        session.delete(hold)

    session.commit()


def get_holds_by_flight(
    *,
    session: Session,
    flight_id: str,
) -> list[SeatHold]:
    return session.exec(
        select(SeatHold)
        .where(SeatHold.flight_id == flight_id)
        .where(SeatHold.expires_at > datetime.utcnow())
    ).all()


# =========================
# BOOKING CRUD
# =========================

def generate_pnr(length: int = 6) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))

def generate_ticket_number() -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=10))

def create_booking(
    *,
    session: Session,
    user: User,
    booking_in: BookingCreate,
) -> Booking:
    
    profile = user.passenger_profile
    if not profile:
        raise ValueError("Passenger profile is required to create a booking")

    required_fields = [
        profile.phone_number,
        profile.passport_number,
        profile.nationality,
        profile.date_of_birth,
    ]

    if any(field is None or field == "" for field in required_fields):
        raise ValueError("Passenger profile is incomplete")

    flight = session.get(Flight, booking_in.flight_id)
    if not flight:
        raise ValueError("Flight not found")

    if flight.status in {FlightStatus.CANCELLED, FlightStatus.DEPARTED}:
        raise ValueError("Cannot book this flight")

    if not booking_in.passengers:
        raise ValueError("At least one passenger is required")
    
    available_seats = session.exec(
        select(FlightSeat)
        .where(FlightSeat.flight_id == flight.id)
        .where(FlightSeat.status == FlightSeatStatus.AVAILABLE)
        .order_by(FlightSeat.row, FlightSeat.seat_label)
    ).all()

    if len(available_seats) < len(booking_in.passengers):
        raise ValueError("Not enough available seats")

    booking = Booking(
        user_id=user.id,
        flight_id=flight.id,
        pnr=generate_pnr(),
        status=BookingStatus.CREATED,
    )

    session.add(booking)
    session.flush()

    used_seat_ids: set[str] = set()
    auto_seat_index = 0

    for passenger in booking_in.passengers:

        if passenger.seat_id:
            seat = session.get(FlightSeat, passenger.seat_id)
            if not seat:
                raise ValueError("Seat not found")
            if seat.flight_id != flight.id:
                raise ValueError("Seat does not belong to this flight")
            if seat.status != FlightSeatStatus.AVAILABLE:
                raise ValueError("Seat is not available")
            if is_seat_held(session=session, flight_seat_id=seat.id):
                raise ValueError("Seat is temporarily held")
        else:
            seat = available_seats[auto_seat_index]
            auto_seat_index += 1

        if seat.id in used_seat_ids:
            raise ValueError("Duplicate seat selection")

        used_seat_ids.add(seat.id)
        seat.status = FlightSeatStatus.BOOKED

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
                passenger_name=passenger.passenger_name,
                seat_number=f"{seat.row}{seat.seat_label}",
                ticket_number=generate_ticket_number(),
            )
        )

    session.commit()
    session.refresh(booking)

    # Автоматическое создание announcement о создании бронирования
    print(f"[BOOKING] Creating auto announcement for booking PNR={booking.pnr}, flight_id={flight.id}")
    try:
        create_auto_announcement(
            session=session,
            flight_id=flight.id,
            announcement_type=AnnouncementType.GENERAL,
            title=f"Booking Created - PNR: {booking.pnr}",
            message=f"Your booking has been created successfully. PNR: {booking.pnr}. Please complete payment to confirm your reservation.",
        )
        print(f"[BOOKING] Successfully created announcement for booking PNR={booking.pnr}")
    except Exception as e:
        # Не прерываем процесс, если announcement не создался
        print(f"[BOOKING] ERROR: Failed to create announcement for booking PNR={booking.pnr}: {e}")

    return booking


def get_booking(
    *,
    session: Session,
    booking_id: str,
) -> Booking | None:
    return session.get(Booking, booking_id)


def get_user_bookings(
    *,
    session: Session,
    user_id: str,
) -> list[Booking]:
    statement = (
        select(Booking)
        .where(Booking.user_id == user_id)
        .order_by(Booking.created_at.desc())
    )
    return session.exec(statement).all()


def get_all_bookings(
    *,
    session: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[Booking]:
    """
    Get all bookings (STAFF only).
    """
    statement = (
        select(Booking)
        .offset(skip)
        .limit(limit)
        .order_by(Booking.created_at.desc())
    )
    return session.exec(statement).all()


def cancel_booking(
    *,
    session: Session,
    booking: Booking,
) -> Booking:
    if booking.status == BookingStatus.CANCELLED:
        return booking

    booking.status = BookingStatus.CANCELLED

    for booking_seat in booking.seats:
        booking_seat.flight_seat.status = FlightSeatStatus.AVAILABLE
    
        release_seat_hold(
        session=session,
        flight_seat_id=booking_seat.flight_seat_id,
        )

    session.commit()
    session.refresh(booking)

    # Автоматическое создание announcement об отмене бронирования
    print(f"[BOOKING_CANCEL] Creating auto announcement for cancelled booking PNR={booking.pnr}, flight_id={booking.flight_id}")
    try:
        create_auto_announcement(
            session=session,
            flight_id=booking.flight_id,
            announcement_type=AnnouncementType.CANCELLATION,
            title=f"Booking Cancelled - PNR: {booking.pnr}",
            message=f"Your booking (PNR: {booking.pnr}) has been cancelled. If you have any questions, please contact our support.",
        )
        print(f"[BOOKING_CANCEL] Successfully created announcement for cancelled booking PNR={booking.pnr}")
    except Exception as e:
        # Не прерываем процесс, если announcement не создался
        print(f"[BOOKING_CANCEL] ERROR: Failed to create announcement for cancelled booking PNR={booking.pnr}: {e}")

    return booking


def confirm_booking(
    *,
    session: Session,
    booking: Booking,
) -> Booking:

    if booking.status != BookingStatus.CREATED:
        raise ValueError("Only CREATED bookings can be confirmed")

    if booking.flight.status in {
        FlightStatus.CANCELLED,
        FlightStatus.DEPARTED,
    }:
        raise ValueError("Cannot confirm booking for this flight")

    booking.status = BookingStatus.CONFIRMED

    session.commit()
    session.refresh(booking)

    return booking

# =========================
# TICKET CRUD
# =========================

def get_all_tickets(
    *,
    session: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[Ticket]:
    """
    Get all tickets (STAFF only).
    """
    statement = (
        select(Ticket)
        .offset(skip)
        .limit(limit)
        .order_by(Ticket.created_at.desc())
    )
    return session.exec(statement).all()


def get_ticket(
    *,
    session: Session,
    ticket_id: str,
) -> Ticket | None:
    return session.get(Ticket, ticket_id)


def get_tickets_by_booking(
    *,
    session: Session,
    booking_id: str,
) -> list[Ticket]:
    statement = (
        select(Ticket)
        .where(Ticket.booking_id == booking_id)
        .order_by(Ticket.created_at)
    )
    return session.exec(statement).all()


def get_ticket_by_number(
    *,
    session: Session,
    ticket_number: str,
) -> Ticket | None:
    statement = select(Ticket).where(Ticket.ticket_number == ticket_number)
    return session.exec(statement).first()


def delete_ticket(
    *,
    session: Session,
    ticket: Ticket,
) -> None:
    if ticket.booking.status == BookingStatus.CONFIRMED:
        raise ValueError("Cannot delete ticket from confirmed booking")
    ticket.flight_seat.status = FlightSeatStatus.AVAILABLE
    release_seat_hold(
    session=session,
    flight_seat_id=ticket.flight_seat_id,
    )
    session.delete(ticket)
    session.commit()


# =========================
# PAYMENT CRUD
# =========================

def create_payment(
    *,
    session: Session,
    booking: Booking,
    method: PaymentMethod,
    idempotency_key: str,
) -> Payment:
    # idempotency
    existing_payment = session.exec(
        select(Payment)
        .where(Payment.idempotency_key == idempotency_key)
    ).first()

    if existing_payment:
        return existing_payment

    if booking.status == BookingStatus.CANCELLED:
        raise ValueError("Cannot pay for cancelled booking")

    if booking.status == BookingStatus.CONFIRMED:
        raise ValueError("Booking already confirmed")

    payment = Payment(
        booking_id=booking.id,
        method=method,
        status=PaymentStatus.PAID,  
        idempotency_key=idempotency_key,
    )

    session.add(payment)

    booking.status = BookingStatus.CONFIRMED

    for booking_seat in booking.seats:
        release_seat_hold(
            session=session,
            flight_seat_id=booking_seat.flight_seat_id,
        )

    session.commit()
    session.refresh(payment)

    # Автоматическое создание announcement об оплате
    print(f"[PAYMENT] Creating auto announcement for payment booking_id={booking.id}, PNR={booking.pnr}, flight_id={booking.flight_id}")
    try:
        create_auto_announcement(
            session=session,
            flight_id=booking.flight_id,
            announcement_type=AnnouncementType.GENERAL,
            title=f"Payment Successful - PNR: {booking.pnr}",
            message=f"Your payment has been processed successfully. Your booking (PNR: {booking.pnr}) is now confirmed. Thank you for choosing our airline!",
        )
        print(f"[PAYMENT] Successfully created announcement for payment PNR={booking.pnr}")
    except Exception as e:
        # Не прерываем процесс, если announcement не создался
        print(f"[PAYMENT] ERROR: Failed to create announcement for payment PNR={booking.pnr}: {e}")

    return payment



def get_payment(
    *,
    session: Session,
    payment_id: str,
) -> Payment | None:
    return session.get(Payment, payment_id)


def get_payments_by_booking(
    *,
    session: Session,
    booking_id: str,
) -> list[Payment]:
    return session.exec(
        select(Payment)
        .where(Payment.booking_id == booking_id)
        .order_by(Payment.created_at.desc())
    ).all()


def get_user_payments(
    *,
    session: Session,
    user_id: str,
) -> list[Payment]:
    return session.exec(
        select(Payment)
        .join(Booking)
        .where(Booking.user_id == user_id)
        .order_by(Payment.created_at.desc())
    ).all()


def get_all_payments(
    *,
    session: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[Payment]:
    """
    Get all payments (STAFF only).
    """
    statement = (
        select(Payment)
        .offset(skip)
        .limit(limit)
        .order_by(Payment.created_at.desc())
    )
    return session.exec(statement).all()


def update_payment_status(
    *,
    session: Session,
    payment: Payment,
    status: PaymentStatus,
) -> Payment:

    payment.status = status

    if status == PaymentStatus.PAID:
        payment.booking.status = BookingStatus.CONFIRMED

    session.commit()
    session.refresh(payment)

    return payment

# =========================
# CHECK-IN CRUD
# =========================

def generate_boarding_qr(*, ticket: Ticket) -> str:
    flight = ticket.booking.flight

    return (
        f"BOARDING_PASS|"
        f"ticket={ticket.ticket_number}|"
        f"flight={flight.flight_number}|"
        f"seat={ticket.seat_number}|"
        f"passenger={ticket.passenger_name}"
    )



def create_checkin(
    *,
    session: Session,
    ticket: Ticket,
) -> CheckIn:
    if ticket.booking.status != BookingStatus.CONFIRMED:
        raise ValueError("Booking must be CONFIRMED")

    existing = session.exec(
        select(CheckIn).where(CheckIn.ticket_id == ticket.id)
    ).first()
    if existing:
        return existing
    
    flight = ticket.booking.flight
    now = datetime.utcnow()

    if flight.departure_time - timedelta(hours=24) > now:
        raise ValueError("Check-in opens 24h before departure")

    if flight.departure_time - timedelta(hours=1) < now:
        raise ValueError("Check-in is closed 1h before departure")

    checkin = CheckIn(
        ticket_id=ticket.id,
    )
    session.add(checkin)
    session.flush()  

    boarding_pass = BoardingPass(
        checkin_id=checkin.id,
        seat_number=ticket.seat_number,
        gate=flight.gate,
        boarding_group="A",  # mock
        qr_code=generate_boarding_qr(ticket=ticket),
    )
    session.add(boarding_pass)

    session.commit()
    session.refresh(checkin)
    return checkin


def get_checkin_by_ticket(
    *,
    session: Session,
    ticket_id: str,
) -> CheckIn | None:
    return session.exec(
        select(CheckIn).where(CheckIn.ticket_id == ticket_id)
    ).first()


def get_checkin(
    *,
    session: Session,
    checkin_id: str,
) -> CheckIn | None:
    return session.get(CheckIn, checkin_id)


def get_checkins_by_flight(
    *,
    session: Session,
    flight_id: str,
) -> list[CheckIn]:
    """
    STAFF use-case:
    all check-ins for a flight
    """
    return session.exec(
        select(CheckIn)
        .join(CheckIn.ticket)
        .join(Ticket.booking)
        .where(Booking.flight_id == flight_id)
        .order_by(CheckIn.checked_in_at)
    ).all()


def delete_checkin(
    *,
    session: Session,
    checkin: CheckIn,
) -> None:
    """
    Mostly for admin/debug.
    BoardingPass will be deleted via cascade.
    """
    session.delete(checkin)
    session.commit()


# =========================
# ANNOUNCEMENTS CRUD
# =========================

def _require_staff(user: User) -> None:
    if user.role != UserRole.STAFF:
        raise ValueError("Staff only")


def _ensure_flight_exists(*, session: Session, flight_id: str) -> Flight:
    flight = session.get(Flight, flight_id)
    if not flight:
        raise ValueError("Flight not found")
    return flight


def _user_has_booking_for_flight(
    *,
    session: Session,
    user_id: str,
    flight_id: str,
) -> bool:
    booking = session.exec(
        select(Booking.id)
        .where(Booking.user_id == user_id)
        .where(Booking.flight_id == flight_id)
        .limit(1)
    ).first()
    return booking is not None


def create_auto_announcement(
    *,
    session: Session,
    flight_id: str,
    announcement_type: AnnouncementType,
    title: str,
    message: str,
) -> Announcement:
    """
    Автоматическое создание announcement при событиях.
    Не требует staff прав, так как вызывается системой.
    """
    print(f"[AUTO_ANNOUNCEMENT] Creating announcement for flight_id={flight_id}")
    print(f"[AUTO_ANNOUNCEMENT] Type: {announcement_type}, Title: {title}")
    
    _ensure_flight_exists(session=session, flight_id=flight_id)

    ann = Announcement(
        id=str(uuid.uuid4()),
        flight_id=flight_id,
        title=title,
        message=message,
        type=announcement_type,
        created_at=datetime.utcnow(),
        created_by_user_id=None,  # Системное создание
    )

    session.add(ann)
    session.commit()
    session.refresh(ann)
    
    print(f"[AUTO_ANNOUNCEMENT] Successfully created announcement id={ann.id}")
    return ann


def create_announcement(
    *,
    session: Session,
    current_user: User,
    announcement_in: AnnouncementCreate,
) -> Announcement:
    """
    STAFF only.
    Create announcement for a flight.
    """
    _require_staff(current_user)
    _ensure_flight_exists(session=session, flight_id=announcement_in.flight_id)

    ann = Announcement(
        id=str(uuid.uuid4()),
        flight_id=announcement_in.flight_id,
        title=announcement_in.title,
        message=announcement_in.message,
        type=announcement_in.type,
        created_at=datetime.utcnow(),
        created_by_user_id=current_user.id,  # опционально, но полезно
    )

    session.add(ann)
    session.commit()
    session.refresh(ann)
    return ann


def update_announcement(
    *,
    session: Session,
    current_user: User,
    announcement: Announcement,
    announcement_in: AnnouncementUpdate,
) -> Announcement:
    """
    STAFF only.
    Partial update.
    """
    _require_staff(current_user)

    if announcement_in.title is not None:
        announcement.title = announcement_in.title
    if announcement_in.message is not None:
        announcement.message = announcement_in.message
    if announcement_in.type is not None:
        announcement.type = announcement_in.type

    session.add(announcement)
    session.commit()
    session.refresh(announcement)
    return announcement


def delete_announcement(
    *,
    session: Session,
    current_user: User,
    announcement: Announcement,
) -> None:
    """
    STAFF only.
    """
    _require_staff(current_user)
    session.delete(announcement)
    session.commit()


def get_announcement(
    *,
    session: Session,
    announcement_id: str,
) -> Optional[Announcement]:
    return session.get(Announcement, announcement_id)


def get_announcements_by_flight(
    *,
    session: Session,
    current_user: User,
    flight_id: str,
    include_past: bool = True,
) -> list[Announcement]:
    """
    Passenger: only if has booking for this flight.
    Staff: always.

    include_past:
      - True: отдаём всё
      - False: можно ограничить будущими/актуальными (если добавишь поле active_until и т.п.)
    """
    _ensure_flight_exists(session=session, flight_id=flight_id)

    if current_user.role != UserRole.STAFF:
        if not _user_has_booking_for_flight(
            session=session,
            user_id=current_user.id,
            flight_id=flight_id,
        ):
            raise ValueError("Not enough permissions")

    stmt = (
        select(Announcement)
        .where(Announcement.flight_id == flight_id)
        .order_by(Announcement.created_at.desc())
    )
    return session.exec(stmt).all()


def get_user_announcements(
    *,
    session: Session,
    current_user: User,
) -> list[Announcement]:
    """
    Passenger "My announcements":
    join Booking -> Announcement via flight_id

    Staff: можно вернуть всё по всем рейсам (или тоже через bookings — на твой выбор).
    Ниже: staff получает всё.
    """
    if current_user.role == UserRole.STAFF:
        stmt = select(Announcement).order_by(Announcement.created_at.desc())
        return session.exec(stmt).all()

    stmt = (
        select(Announcement)
        .join(Booking, Booking.flight_id == Announcement.flight_id)
        .where(Booking.user_id == current_user.id)
        .order_by(Announcement.created_at.desc())
    )
    # если у пользователя несколько booking на один рейс — будут дубликаты.
    # В SQLite distinct по всей модели может быть капризным, поэтому:
    anns = session.exec(stmt).all()

    # Убираем дубликаты аккуратно по id
    uniq: dict[str, Announcement] = {}
    for a in anns:
        uniq[a.id] = a
    return list(uniq.values())
