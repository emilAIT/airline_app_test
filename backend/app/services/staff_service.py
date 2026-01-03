from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from .. import models, schemas
from ..enums import FlightStatus, SeatCategory, BookingStatus
from fastapi import HTTPException, status
import datetime

# Helper to calculate available seats
def get_available_seats_count(db: Session, flight_id: int) -> int:
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        return 0
    total_seats = flight.airplane.total_seats
    booked_seats = db.query(func.count(models.Booking.id)).filter(
        and_(
            models.Booking.flight_id == flight_id,
            models.Booking.status == BookingStatus.CONFIRMED
        )
    ).scalar() or 0
    return total_seats - booked_seats

def _map_flight_response(db: Session, flight: models.Flight) -> dict:
    available_seats = get_available_seats_count(db, flight.id)
    duration = (flight.arrival_time - flight.departure_time).total_seconds() / 60
    return {
        "id": flight.id,
        "flight_number": flight.flight_number,
        "airplane_id": flight.airplane_id,
        "origin_airport_id": flight.origin_airport_id,
        "destination_airport_id": flight.destination_airport_id,
        "departure_time": flight.departure_time,
        "arrival_time": flight.arrival_time,
        "duration_minutes": int(duration),
        "base_price": flight.base_price,
        "available_seats": available_seats,
        "gate": flight.gate,
        "terminal": flight.terminal,
        "status": flight.status,
        "boarding_time": flight.boarding_time,
        "origin_airport": flight.origin_airport,
        "destination_airport": flight.destination_airport,
        "airplane": flight.airplane
    }

def create_airplane(db: Session, airplane_data: schemas.AirplaneCreate) -> models.Airplane:
    # Determine registration
    registration = airplane_data.registration
    if not registration:
        # Generate random registration
        import random, string
        while True:
            suffix = ''.join(random.choices(string.ascii_uppercase, k=3))
            test_reg = f"TC-{suffix}"
            existing = db.query(models.Airplane).filter(models.Airplane.registration == test_reg).first()
            if not existing:
                registration = test_reg
                break
    else:
        # Check if registration exists
        existing = db.query(models.Airplane).filter(models.Airplane.registration == registration).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Airplane with this registration already exists"
            )

    # Determine seats
    if airplane_data.seat_templates:
        total_seats = len(airplane_data.seat_templates)
    elif airplane_data.total_seats:
        total_seats = airplane_data.total_seats
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Must provide seat_templates or total_seats"
        )

    # Create airplane
    airplane = models.Airplane(
        model=airplane_data.model,
        registration=registration,
        total_seats=total_seats
    )
    db.add(airplane)
    db.flush()
    
    # Create seat templates
    if airplane_data.seat_templates:
        for seat_data in airplane_data.seat_templates:
            seat = models.SeatTemplate(
                airplane_id=airplane.id,
                row_number=seat_data.row_number,
                seat_label=seat_data.seat_label,
                category=seat_data.category
            )
            db.add(seat)
    else:
        # Generate standard layout (6 abreast)
        from ..enums import SeatCategory
        labels = ['A', 'B', 'C', 'D', 'E', 'F']
        count = 0
        row = 1
        while count < total_seats:
            for label in labels:
                if count >= total_seats:
                    break
                seat = models.SeatTemplate(
                    airplane_id=airplane.id,
                    row_number=row,
                    seat_label=label,
                    category=SeatCategory.STANDARD
                )
                db.add(seat)
                count += 1
            row += 1
    
    db.commit()
    db.refresh(airplane)
    
    return airplane


def get_all_airplanes(db: Session) -> List[models.Airplane]:
    return db.query(models.Airplane).all()


    return airplane


def update_airplane(db: Session, airplane_id: int, airplane_data: schemas.AirplaneUpdate) -> models.Airplane:
    airplane = db.query(models.Airplane).filter(models.Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airplane not found")
    
    # Check if capacity is changing
    if airplane_data.total_seats and airplane_data.total_seats != airplane.total_seats:
        # Update capacity - regenerate seats
        airplane.total_seats = airplane_data.total_seats
        
        # Delete existing templates
        db.query(models.SeatTemplate).filter(models.SeatTemplate.airplane_id == airplane.id).delete()
        
        # Generate new standard layout
        from ..enums import SeatCategory
        labels = ['A', 'B', 'C', 'D', 'E', 'F']
        count = 0
        row = 1
        while count < airplane.total_seats:
            for label in labels:
                if count >= airplane.total_seats:
                    break
                seat = models.SeatTemplate(
                    airplane_id=airplane.id,
                    row_number=row,
                    seat_label=label,
                    category=SeatCategory.STANDARD
                )
                db.add(seat)
                count += 1
            row += 1

    # Update other fields
    if airplane_data.model:
        airplane.model = airplane_data.model
    if airplane_data.registration:
        airplane.registration = airplane_data.registration
    elif airplane_data.manufacturer:
        # Ignore manufacturer if registration exists or isn't changing?
        # Assuming manufacturer is just a label for model prefix? 
        # Ignoring for now as model/reg are primary.
        pass

    db.commit()
    db.refresh(airplane)
    return airplane


def get_airplane_detail(db: Session, airplane_id: int) -> models.Airplane:
    airplane = db.query(models.Airplane).filter(models.Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airplane not found")
    return airplane


def create_flight(db: Session, flight_data: schemas.FlightCreate) -> models.Flight:
    # Validate airplane exists
    airplane = db.query(models.Airplane).filter(models.Airplane.id == flight_data.airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airplane not found")
    
    # Validate airports exist
    origin = db.query(models.Airport).filter(models.Airport.id == flight_data.origin_airport_id).first()
    destination = db.query(models.Airport).filter(models.Airport.id == flight_data.destination_airport_id).first()
    
    if not origin or not destination:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Airport not found")
    
    # Check if flight number exists
    existing = db.query(models.Flight).filter(models.Flight.flight_number == flight_data.flight_number).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Flight number already exists"
        )
    
    # Create flight
    flight = models.Flight(
        flight_number=flight_data.flight_number,
        airplane_id=flight_data.airplane_id,
        origin_airport_id=flight_data.origin_airport_id,
        destination_airport_id=flight_data.destination_airport_id,
        departure_time=flight_data.departure_time,
        arrival_time=flight_data.arrival_time,
        base_price=flight_data.base_price,
        gate=flight_data.gate,
        terminal=flight_data.terminal,
        boarding_time=flight_data.boarding_time,
        status=FlightStatus.SCHEDULED
    )
    db.add(flight)
    db.commit()
    db.refresh(flight)
    
    return _map_flight_response(db, flight)


def get_all_flights(db: Session) -> List[dict]:
    flights = db.query(models.Flight).all()
    return [_map_flight_response(db, f) for f in flights]


def get_flight_detail(db: Session, flight_id: int) -> dict:
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    return _map_flight_response(db, flight)


def update_flight(db: Session, flight_id: int, flight_data: schemas.FlightUpdate) -> dict:
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    
    # Update only provided fields
    if flight_data.departure_time is not None:
        flight.departure_time = flight_data.departure_time
    if flight_data.arrival_time is not None:
        flight.arrival_time = flight_data.arrival_time
    if flight_data.gate is not None:
        flight.gate = flight_data.gate
    if flight_data.terminal is not None:
        flight.terminal = flight_data.terminal
    if flight_data.status is not None:
        flight.status = flight_data.status
    if flight_data.boarding_time is not None:
        flight.boarding_time = flight_data.boarding_time
    
    db.commit()
    db.refresh(flight)
    
    return _map_flight_response(db, flight)


def delete_flight(db: Session, flight_id: int):
    flight = db.query(models.Flight).filter(models.Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    
    # Check if there are confirmed bookings
    confirmed_bookings = db.query(models.Booking).filter(
        and_(
            models.Booking.flight_id == flight_id,
            models.Booking.status == BookingStatus.CONFIRMED
        )
    ).first()
    
    if confirmed_bookings:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete flight with confirmed bookings"
        )
    
    # Get all booking IDs for this flight (non-confirmed ones)
    booking_ids = [b.id for b in db.query(models.Booking.id).filter(models.Booking.flight_id == flight_id).all()]
    
    if booking_ids:
        # Get all ticket IDs for these bookings
        ticket_ids = [t.id for t in db.query(models.Ticket.id).filter(models.Ticket.booking_id.in_(booking_ids)).all()]
        
        if ticket_ids:
            # Delete check-ins for these tickets
            db.query(models.CheckIn).filter(models.CheckIn.ticket_id.in_(ticket_ids)).delete(synchronize_session=False)
        
        # Delete tickets for these bookings
        db.query(models.Ticket).filter(models.Ticket.booking_id.in_(booking_ids)).delete(synchronize_session=False)
        
        # Delete payments for these bookings
        db.query(models.Payment).filter(models.Payment.booking_id.in_(booking_ids)).delete(synchronize_session=False)
        
        # Delete the bookings
        db.query(models.Booking).filter(models.Booking.id.in_(booking_ids)).delete(synchronize_session=False)
    
    # Delete related announcements
    db.query(models.Announcement).filter(models.Announcement.flight_id == flight_id).delete(synchronize_session=False)
    
    # Delete related seat holds
    db.query(models.SeatHold).filter(models.SeatHold.flight_id == flight_id).delete(synchronize_session=False)
    
    # Delete the flight
    db.query(models.Flight).filter(models.Flight.id == flight_id).delete(synchronize_session=False)
    db.commit()




def create_announcement(db: Session, announcement_data: schemas.AnnouncementCreate) -> models.Announcement:
    # Validate flight exists
    flight = db.query(models.Flight).filter(models.Flight.id == announcement_data.flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    
    announcement = models.Announcement(
        flight_id=announcement_data.flight_id,
        type=announcement_data.type,
        title=announcement_data.title,
        message=announcement_data.message
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    
    return announcement


def get_all_announcements(db: Session) -> List[models.Announcement]:
    return db.query(models.Announcement).order_by(models.Announcement.created_at.desc()).all()


def delete_announcement(db: Session, announcement_id: int):
    announcement = db.query(models.Announcement).filter(models.Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Announcement not found")
    
    db.delete(announcement)
    db.commit()


def get_flight_announcements(db: Session, flight_id: int) -> List[models.Announcement]:
    return db.query(models.Announcement).filter(
        models.Announcement.flight_id == flight_id
    ).order_by(models.Announcement.created_at.desc()).all()


def get_user_announcements(db: Session, user_id: int) -> List[models.Announcement]:
    # Get all user's confirmed bookings
    bookings = db.query(models.Booking).filter(
        and_(
            models.Booking.user_id == user_id,
            models.Booking.status == "CONFIRMED"
        )
    ).all()
    
    flight_ids = [b.flight_id for b in bookings]
    
    # Get announcements for those flights
    announcements = db.query(models.Announcement).filter(
        models.Announcement.flight_id.in_(flight_ids)
    ).order_by(models.Announcement.created_at.desc()).all()
    
    return announcements

