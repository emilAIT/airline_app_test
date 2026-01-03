from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from datetime import datetime, date
from typing import List, Optional
from .. import models, schemas
from ..enums import FlightStatus, BookingStatus


def search_flights(
    db: Session,
    origin_code: str,
    destination_code: str,
    departure_date: date
) -> List[dict]:
    # Get airports
    origin = db.query(models.Airport).filter(models.Airport.code == origin_code.upper()).first()
    destination = db.query(models.Airport).filter(models.Airport.code == destination_code.upper()).first()
    
    if not origin or not destination:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    
    # Search flights
    start_of_day = datetime.combine(departure_date, datetime.min.time())
    end_of_day = datetime.combine(departure_date, datetime.max.time())
    
    flights = db.query(models.Flight).filter(
        and_(
            models.Flight.origin_airport_id == origin.id,
            models.Flight.destination_airport_id == destination.id,
            models.Flight.departure_time >= start_of_day,
            models.Flight.departure_time <= end_of_day,
            models.Flight.status != FlightStatus.CANCELLED
        )
    ).all()
    
    results = []
    for flight in flights:
        available_seats = get_available_seats_count(db, flight.id)
        duration = (flight.arrival_time - flight.departure_time).total_seconds() / 60
        
        results.append({
            "id": flight.id,
            "flight_number": flight.flight_number,
            "departure_time": flight.departure_time,
            "arrival_time": flight.arrival_time,
            "duration_minutes": int(duration),
            "base_price": flight.base_price,
            "available_seats": available_seats,
            "available_seats": available_seats,
            "status": flight.status,
            "origin_airport": flight.origin_airport,
            "destination_airport": flight.destination_airport
        })
    
    return results


def get_flight_detail(db: Session, flight_id: int) -> models.Flight:
    from sqlalchemy.orm import joinedload
    flight = db.query(models.Flight)\
        .options(
            joinedload(models.Flight.origin_airport),
            joinedload(models.Flight.destination_airport),
            joinedload(models.Flight.airplane)
        )\
        .filter(models.Flight.id == flight_id)\
        .first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    return flight


def get_available_seats_count(db: Session, flight_id: int) -> int:
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        return 0
    
    total_seats = flight.airplane.total_seats
    
    # Count confirmed tickets
    booked_count = db.query(models.Ticket).join(models.Booking).filter(
        and_(
            models.Booking.flight_id == flight_id,
            models.Booking.status == BookingStatus.CONFIRMED
        )
    ).count()
    
    # Count held seats (not yet released)
    held_count = db.query(models.SeatHold).filter(
        and_(
            models.SeatHold.flight_id == flight_id,
            models.SeatHold.held_until > datetime.utcnow()
        )
    ).count()
    
    return total_seats - booked_count - held_count


def get_seat_map(db: Session, flight_id: int) -> dict:
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    
    # Get all seats from airplane template
    seat_templates = db.query(models.SeatTemplate).filter(
        models.SeatTemplate.airplane_id == flight.airplane_id
    ).order_by(models.SeatTemplate.row_number, models.SeatTemplate.seat_label).all()
    
    # Get booked seats
    booked_seats = set()
    confirmed_tickets = db.query(models.Ticket).join(models.Booking).filter(
        and_(
            models.Booking.flight_id == flight_id,
            models.Booking.status == BookingStatus.CONFIRMED
        )
    ).all()
    for ticket in confirmed_tickets:
        booked_seats.add(ticket.seat_number)
    
    # Get held seats
    held_seats = db.query(models.SeatHold).filter(
        and_(
            models.SeatHold.flight_id == flight_id,
            models.SeatHold.held_until > datetime.utcnow()
        )
    ).all()
    for hold in held_seats:
        booked_seats.add(hold.seat_number)
    
    # Build seat map
    seats = []
    for template in seat_templates:
        seat_number = f"{template.row_number}{template.seat_label}"
        price = flight.base_price
        if template.category == "EXTRA_LEGROOM":
            price = flight.base_price * 1.5
        
        seats.append({
            "seat_number": seat_number,
            "category": template.category,
            "is_available": seat_number not in booked_seats,
            "price": price
        })
    
    return {
        "flight_id": flight_id,
        "seats": seats
    }


def get_all_airports(db: Session) -> List[models.Airport]:
    return db.query(models.Airport).all()

