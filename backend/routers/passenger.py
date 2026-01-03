from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, date
from app.core.database import get_db
from app.core.dependencies import get_current_passenger
from app.models.user import User
from app.models.airport import Airport
from app.schemas.flight import FlightSearchRequest
from app.schemas.booking import BookingCreate
from app.schemas.payment import PaymentCreate
from app.services import flight_service, booking_service, payment_service, checkin_service, announcement_service

router = APIRouter(prefix="/passenger", tags=["Passenger"])


@router.get("/airports")
def list_airports_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    List all airports for search dropdowns.
    """
    airports = db.query(Airport).order_by(Airport.city).all()
    return [
        {
            "id": airport.id,
            "code": airport.code,
            "name": airport.name,
            "city": airport.city,
            "country": airport.country
        }
        for airport in airports
    ]


@router.get("/flights/search")
def search_flights_endpoint(
    origin_id: int,
    destination_id: int,
    departure_date: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    Search flights by origin, destination, and date.
    Per instructions.txt lines 199-211.
    """
    try:
        parsed_date = datetime.strptime(departure_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date format. Use YYYY-MM-DD"
        )
    
    return flight_service.search_flights(db, origin_id, destination_id, parsed_date)


@router.get("/flights/{flight_id}")
def get_flight_endpoint(
    flight_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """Get flight details with available seats"""
    flight = flight_service.get_flight(db, flight_id)
    available_seats_list = booking_service.get_available_seats(db, flight_id)
    
    # Get all booked/held seats
    held_seats = set()
    from app.models.seat_hold import SeatHold
    from app.models.ticket import Ticket
    from app.models.booking import Booking, BookingStatus
    
    for hold in db.query(SeatHold).filter(SeatHold.flight_id == flight_id).all():
        held_seats.add(hold.seat_number)
    
    for ticket in db.query(Ticket).join(Booking).filter(
        Booking.flight_id == flight_id,
        Booking.status == BookingStatus.CONFIRMED
    ).all():
        held_seats.add(ticket.seat_number)
    
    # Build seat map for frontend
    seat_template = flight.airplane.seat_template
    rows_count = seat_template.get("rows", 30)
    seats_per_row = seat_template.get("seats_per_row", 6)
    seat_letters = "ABCDEFGHIJ"[:seats_per_row]
    
    # Create seat map structure
    seat_map_rows = []
    for row_num in range(1, rows_count + 1):
        row_data = {
            "row": row_num,
            "seats": {}
        }
        for letter in seat_letters:
            seat_id = f"{row_num}{letter}"
            row_data["seats"][letter] = seat_id not in held_seats  # True = available
        seat_map_rows.append(row_data)
    
    # Determine config based on seats_per_row
    if seats_per_row == 6:
        config = "ABC_DEF"
    elif seats_per_row == 4:
        config = "AB_CD"
    else:
        config = seat_letters[:seats_per_row // 2] + "_" + seat_letters[seats_per_row // 2:]
    
    return {
        "flight": {
            "id": flight.id,
            "flight_number": flight.flight_number,
            "scheduled_departure": flight.scheduled_departure.isoformat(),
            "scheduled_arrival": flight.scheduled_arrival.isoformat(),
            "status": flight.status.value,
            "gate": flight.gate,
            "terminal": flight.terminal,
            "price": flight.price,
            "origin_airport": {
                "id": flight.origin_airport.id,
                "code": flight.origin_airport.code,
                "name": flight.origin_airport.name,
                "city": flight.origin_airport.city,
                "country": flight.origin_airport.country
            },
            "destination_airport": {
                "id": flight.destination_airport.id,
                "code": flight.destination_airport.code,
                "name": flight.destination_airport.name,
                "city": flight.destination_airport.city,
                "country": flight.destination_airport.country
            },
            "airplane": {
                "id": flight.airplane.id,
                "model": flight.airplane.model,
                "registration_number": flight.airplane.registration_number,
                "seat_template": {
                    "rows": seat_map_rows,
                    "config": config
                },
                "total_seats": flight.airplane.total_seats
            }
        },
        "available_seats_count": len(available_seats_list),
        "available_seats": available_seats_list[:50]  # Limit to first 50 for performance
    }


@router.post("/bookings", status_code=status.HTTP_201_CREATED)
def create_booking_endpoint(
    booking_data: BookingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    Create a new booking with seat holds.
    Per instructions.txt booking flow lines 169-182.
    """
    booking = booking_service.create_booking(
        db,
        user_id=current_user.id,
        flight_id=booking_data.flight_id,
        passenger_data_list=booking_data.passengers
    )
    
    # Serialize booking properly
    return {
        "id": booking.id,
        "pnr": booking.pnr,
        "user_id": booking.user_id,
        "flight_id": booking.flight_id,
        "status": booking.status.value,
        "held_until": booking.held_until.isoformat() if booking.held_until else None,
        "created_at": booking.created_at.isoformat(),
        "tickets": [
            {
                "id": ticket.id,
                "ticket_number": ticket.ticket_number,
                "seat_number": ticket.seat_number
            }
            for ticket in booking.tickets
        ]
    }


@router.get("/bookings/upcoming")
def get_upcoming_bookings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """Get upcoming trips"""
    bookings = booking_service.get_user_bookings(db, current_user.id, upcoming_only=True)
    return [
        {
            "id": booking.id,
            "pnr": booking.pnr,
            "user_id": booking.user_id,
            "flight_id": booking.flight_id,
            "status": booking.status.value,
            "held_until": booking.held_until.isoformat() if booking.held_until else None,
            "created_at": booking.created_at.isoformat(),
            "tickets": [
                {
                    "id": ticket.id,
                    "ticket_number": ticket.ticket_number,
                    "seat_number": ticket.seat_number
                }
                for ticket in booking.tickets
            ]
        }
        for booking in bookings
    ]


@router.get("/bookings/past")
def get_past_bookings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """Get past trips"""
    bookings = booking_service.get_user_bookings(db, current_user.id, past_only=True)
    return [
        {
            "id": booking.id,
            "pnr": booking.pnr,
            "user_id": booking.user_id,
            "flight_id": booking.flight_id,
            "status": booking.status.value,
            "held_until": booking.held_until.isoformat() if booking.held_until else None,
            "created_at": booking.created_at.isoformat(),
            "tickets": [
                {
                    "id": ticket.id,
                    "ticket_number": ticket.ticket_number,
                    "seat_number": ticket.seat_number
                }
                for ticket in booking.tickets
            ]
        }
        for booking in bookings
    ]


@router.get("/bookings")
def get_all_bookings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """Get all user bookings (upcoming and past)"""
    bookings = booking_service.get_user_bookings(db, current_user.id)
    return [
        {
            "id": booking.id,
            "pnr": booking.pnr,
            "user_id": booking.user_id,
            "flight_id": booking.flight_id,
            "status": booking.status.value,
            "held_until": booking.held_until.isoformat() if booking.held_until else None,
            "created_at": booking.created_at.isoformat(),
            "flight": {
                "id": booking.flight.id,
                "flight_number": booking.flight.flight_number,
                "scheduled_departure": booking.flight.scheduled_departure.isoformat(),
                "scheduled_arrival": booking.flight.scheduled_arrival.isoformat(),
                "status": booking.flight.status.value,
                "gate": booking.flight.gate,
                "terminal": booking.flight.terminal,
                "origin": {
                    "id": booking.flight.origin_airport.id,
                    "code": booking.flight.origin_airport.code,
                    "name": booking.flight.origin_airport.name,
                    "city": booking.flight.origin_airport.city,
                    "country": booking.flight.origin_airport.country,
                },
                "destination": {
                    "id": booking.flight.destination_airport.id,
                    "code": booking.flight.destination_airport.code,
                    "name": booking.flight.destination_airport.name,
                    "city": booking.flight.destination_airport.city,
                    "country": booking.flight.destination_airport.country,
                },
                "airplane": {
                    "id": booking.flight.airplane.id,
                    "model": booking.flight.airplane.model,
                    "registration_number": booking.flight.airplane.registration_number,
                    "total_seats": booking.flight.airplane.total_seats,
                }
            } if booking.flight else None,
            "tickets": [
                {
                    "id": ticket.id,
                    "ticket_number": ticket.ticket_number,
                    "seat_number": ticket.seat_number
                }
                for ticket in booking.tickets
            ]
        }
        for booking in bookings
    ]


@router.post("/bookings/{booking_id}/payment", status_code=status.HTTP_201_CREATED)
def process_payment_endpoint(
    booking_id: int,
    payment_data: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    Process payment for a booking (mock payment).
    Idempotent per instructions.txt line 193.
    """
    # Verify booking belongs to user
    bookings = booking_service.get_user_bookings(db, current_user.id, upcoming_only=True)
    booking = next((b for b in bookings if b.id == booking_id), None)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    payment = payment_service.process_payment(
        db,
        booking_id=booking_id,
        payment_method=payment_data.payment_method,
        idempotency_key=payment_data.idempotency_key
    )
    return {
        "id": payment.id,
        "booking_id": payment.booking_id,
        "amount": payment.amount,
        "payment_method": payment.payment_method.value,
        "status": payment.status.value,
        "idempotency_key": payment.idempotency_key,
        "transaction_id": payment.transaction_id,
        "created_at": payment.created_at.isoformat()
    }
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    payment = payment_service.process_payment(
        db,
        booking_id=booking_id,
        payment_method=payment_data.payment_method,
        idempotency_key=payment_data.idempotency_key
    )
    return payment


@router.post("/tickets/{ticket_id}/checkin")
def check_in_endpoint(
    ticket_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    Check in for a flight.
    24h to 1h before departure per instructions.txt line 224.
    """
    checkin = checkin_service.check_in_ticket(db, ticket_id, user_id=current_user.id)
    return checkin


@router.get("/tickets/{ticket_id}/boarding-pass")
def get_boarding_pass_endpoint(
    ticket_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    Get boarding pass with QR code.
    Per instructions.txt lines 227-233.
    """
    boarding_pass = checkin_service.get_boarding_pass(db, ticket_id, user_id=current_user.id)
    return boarding_pass


@router.get("/announcements")
def get_announcements_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_passenger)
):
    """
    View announcements for user's flights.
    Per instructions.txt lines 236-245.
    """
    # Get user's upcoming bookings
    bookings = booking_service.get_user_bookings(db, current_user.id, upcoming_only=True)
    flight_ids = [b.flight_id for b in bookings]
    
    # Get announcements for these flights
    all_announcements = []
    for flight_id in flight_ids:
        announcements = announcement_service.get_announcements(db, flight_id=flight_id)
        all_announcements.extend(announcements)
    
    return all_announcements
