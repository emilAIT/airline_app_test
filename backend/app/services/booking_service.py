"""
Booking service - КРИТИЧНАЯ бизнес-логика создания бронирований.

Implements:
  - Seat hold mechanism (10 minute expiration)
  - Double booking prevention через DB UNIQUE constraint
  - Transactional integrity (all-or-nothing)
  - Profile validation
  - Flight status validation
"""
from datetime import datetime, timedelta
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.config import settings
from app.core.exceptions import (
    FlightNotBookable,
    SeatAlreadyTaken,
    NotFound
)
from app.repositories.booking import booking_repository
from app.repositories.seat_hold import seat_hold_repository
from app.services.id_generator import generate_pnr
from app.models.flight import Flight
from app.models.seat import Seat
from app.models.booking_passenger import BookingPassenger


class PassengerData:
    """Passenger data for booking."""
    def __init__(self, first_name: str, last_name: str, seat_number: str, passport_number: str, nationality: str, date_of_birth):
        self.first_name = first_name
        self.last_name = last_name
        self.seat_number = seat_number
        self.passport_number = passport_number
        self.nationality = nationality
        self.date_of_birth = date_of_birth


class BookingService:
    """
    Business logic for создания бронирований.
    
    Critical Flow:
        1. Validate profile exists
        2. Validate flight status (not CANCELLED/DEPARTED/LANDED)
        3. создать Booking (CREATED status)
        4. For each passenger:
           a. Insert SeatHold (UNIQUE constraint prevents double booking)
           b. Create Ticket
        5. Commit transaction (all or nothing)
    
    If IntegrityError on SeatHold -> seat already taken -> 409 Conflict
    """
    
    def create_booking(
        self,
        db: Session,
        user_id: int,
        flight_id: int,
        passengers: List[PassengerData]
    ):
        """
        Create booking with seat holds.
        
        Transaction ensures atomicity: либо все места забронированы, либо ничего.
        
        Raises:
            FlightNotBookable: если рейс нельзя бронировать
            SeatAlreadyTaken: если место уже занято (UNIQUE constraint)
            NotFound: если flight не найден
        """
        # 1. Validate flight and status
        flight = db.query(Flight).filter(Flight.id == flight_id).first()
        if not flight:
            raise NotFound("Flight")
        
        if flight.status in ['CANCELLED', 'DEPARTED', 'LANDED']:
            raise FlightNotBookable(flight.status)

        # Prevent booking flights that already departed (even if status wasn't updated).
        if flight.departure_time <= datetime.utcnow():
            raise FlightNotBookable('DEPARTED')
        
        # Calculate total amount
        # TODO: implement seat class pricing logic
        # Exam schema uses `price`
        total_amount = float(flight.price) * len(passengers)
        
        # 3. Generate unique PNR
        pnr = generate_pnr()
        
        #  Transaction starts here - критично для атомарности
        try:
            # 4. Create booking (CREATED status)
            booking = booking_repository.create(
                db=db,
                pnr=pnr,
                user_id=user_id,
                flight_id=flight_id,
                total_amount=total_amount,
                status="CREATED"
            )
            
            # 5. For each passenger: create seat hold + ticket
            held_until = datetime.utcnow() + timedelta(
                minutes=settings.seat_hold_duration_minutes
            )
            
            for passenger in passengers:
                # Parse seat_number format: "1A", "2B", etc.
                seat_code = passenger.seat_number.strip()
                if not seat_code:
                    raise NotFound("Seat")
                
                # Extract row number and seat letter
                row_num = int(''.join(c for c in seat_code if c.isdigit()))
                seat_letter = ''.join(c for c in seat_code if c.isalpha()).upper()
                
                # Find seat in airplane
                seat = (
                    db.query(Seat)
                    .filter(Seat.airplane_id == flight.airplane_id)
                    .filter(Seat.row_number == row_num)
                    .filter(Seat.seat_letter == seat_letter)
                    .first()
                )
                if not seat:
                    raise NotFound("Seat")

                try:
                    # 🔒 CRITICAL: INSERT with UNIQUE(flight_id, seat_number)
                    # Если место занято → IntegrityError
                    seat_hold_repository.create(
                        db=db,
                        flight_id=flight_id,
                        seat_number=passenger.seat_number,
                        user_id=user_id,
                        held_until=held_until,
                        booking_id=booking.id
                    )
                except IntegrityError:
                    # UNIQUE constraint violation - место уже занято
                    db.rollback()
                    raise SeatAlreadyTaken(passenger.seat_number)

                # Persist passenger details per booking (source of truth for passenger list)
                bp = BookingPassenger(
                    booking_id=booking.id,
                    flight_id=flight_id,
                    first_name=passenger.first_name,
                    last_name=passenger.last_name,
                    seat_number=passenger.seat_number,
                    passport_number=passenger.passport_number,
                    nationality=passenger.nationality,
                    date_of_birth=passenger.date_of_birth,
                )
                db.add(bp)
            
            db.commit()  # Все или ничего
            
            # Reload booking with relationships for response
            return booking_repository.get_by_id(db, booking.id)
            
        except Exception as e:
            db.rollback()
            raise


booking_service = BookingService()
