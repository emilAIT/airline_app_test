from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from datetime import datetime, date
from app.models.flight import Flight, FlightStatus
from app.models.airplane import Airplane
from app.models.airport import Airport
from app.models.booking import Booking, BookingStatus
from app.models.seat_hold import SeatHold
from app.models.ticket import Ticket
from app.services.booking_service import cleanup_expired_holds


def search_flights(
    db: Session,
    origin_id: int,
    destination_id: int,
    departure_date: date
) -> list:
    """
    Search flights by origin, destination, and departure date.
    Per instructions.txt lines 199-211, results include:
    - Flight number, departure/arrival times, duration, price, available seats, status
    """
    # Query flights
    flights = db.query(Flight).filter(
        and_(
            Flight.origin_id == origin_id,
            Flight.destination_id == destination_id,
            Flight.scheduled_departure >= datetime.combine(departure_date, datetime.min.time()),
            Flight.scheduled_departure < datetime.combine(
                departure_date, datetime.max.time()
            )
        )
    ).all()
    
    results = []
    for flight in flights:
        # Cleanup expired holds for this flight
        cleanup_expired_holds(db, flight.id)
        
        # Calculate available seats
        total_seats = flight.airplane.total_seats
        
        # Count held seats
        held_seats_count = db.query(SeatHold).filter(
            SeatHold.flight_id == flight.id
        ).count()
        
        # Count confirmed seats
        confirmed_seats_count = db.query(Ticket).join(Booking).filter(
            Booking.flight_id == flight.id,
            Booking.status == BookingStatus.CONFIRMED
        ).count()
        
        available_seats = total_seats - held_seats_count - confirmed_seats_count
        
        # Calculate duration
        duration_seconds = (flight.scheduled_arrival - flight.scheduled_departure).total_seconds()
        duration_hours = int(duration_seconds // 3600)
        duration_minutes = int((duration_seconds % 3600) // 60)
        
        results.append({
            "id": flight.id,
            "flight_number": flight.flight_number,
            "departure_time": flight.scheduled_departure,
            "arrival_time": flight.scheduled_arrival,
            "duration": f"{duration_hours}h {duration_minutes}m",
            "price": flight.price,
            "available_seats": max(0, available_seats),
            "status": flight.status.value,
            "origin": {
                "id": flight.origin_airport.id,
                "code": flight.origin_airport.code,
                "name": flight.origin_airport.name,
                "city": flight.origin_airport.city
            },
            "destination": {
                "id": flight.destination_airport.id,
                "code": flight.destination_airport.code,
                "name": flight.destination_airport.name,
                "city": flight.destination_airport.city
            },
            "airplane": {
                "model": flight.airplane.model,
                "total_seats": flight.airplane.total_seats
            }
        })
    
    return results


def get_flight(db: Session, flight_id: int) -> Flight:
    """Get a single flight by ID"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    return flight


def create_flight(
    db: Session,
    flight_number: str,
    origin_id: int,
    destination_id: int,
    airplane_id: int,
    scheduled_departure: datetime,
    scheduled_arrival: datetime,
    price: float,
    gate: str = None,
    terminal: str = None
) -> Flight:
    """Create a new flight (staff only)"""
    # Validate origin and destination are different
    if origin_id == destination_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Origin and destination must be different"
        )
    
    # Check if flight number already exists
    existing = db.query(Flight).filter(Flight.flight_number == flight_number).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Flight number {flight_number} already exists"
        )
    
    # Validate airports exist
    origin = db.query(Airport).filter(Airport.id == origin_id).first()
    if not origin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Origin airport {origin_id} not found"
        )
    
    destination = db.query(Airport).filter(Airport.id == destination_id).first()
    if not destination:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Destination airport {destination_id} not found"
        )
    
    # Validate airplane exists
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Airplane {airplane_id} not found"
        )
    
    # Validate times
    if scheduled_arrival <= scheduled_departure:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Arrival time must be after departure time"
        )
    
    flight = Flight(
        flight_number=flight_number,
        origin_id=origin_id,
        destination_id=destination_id,
        airplane_id=airplane_id,
        scheduled_departure=scheduled_departure,
        scheduled_arrival=scheduled_arrival,
        price=price,
        gate=gate,
        terminal=terminal,
        status=FlightStatus.SCHEDULED
    )
    db.add(flight)
    db.commit()
    db.refresh(flight)
    return flight


def update_flight(db: Session, flight_id: int, update_data: dict) -> Flight:
    """Update flight details (staff only)"""
    flight = get_flight(db, flight_id)
    
    # Update only provided fields
    for key, value in update_data.items():
        if value is not None:
            if key == 'status':
                # Handle status as enum
                try:
                    value = FlightStatus(value.upper())
                except (ValueError, AttributeError):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Invalid status. Must be one of: {[s.value for s in FlightStatus]}"
                    )
            elif key == 'origin_id':
                # Validate origin airport exists
                origin = db.query(Airport).filter(Airport.id == value).first()
                if not origin:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Origin airport {value} not found"
                    )
            elif key == 'destination_id':
                # Validate destination airport exists
                destination = db.query(Airport).filter(Airport.id == value).first()
                if not destination:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Destination airport {value} not found"
                    )
            elif key == 'airplane_id':
                # Validate airplane exists
                airplane = db.query(Airplane).filter(Airplane.id == value).first()
                if not airplane:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Airplane {value} not found"
                    )
            
            setattr(flight, key, value)
    
    # Validate times if both are present
    if flight.scheduled_arrival <= flight.scheduled_departure:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Arrival time must be after departure time"
        )
    
    db.commit()
    db.refresh(flight)
    return flight


def update_flight_status(db: Session, flight_id: int, status: FlightStatus) -> Flight:
    """Update flight status (staff only)"""
    flight = get_flight(db, flight_id)
    flight.status = status
    db.commit()
    db.refresh(flight)
    return flight


def list_flights(db: Session, skip: int = 0, limit: int = 100) -> list:
    """List all flights"""
    return db.query(Flight).offset(skip).limit(limit).all()
