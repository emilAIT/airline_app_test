from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from datetime import datetime, timedelta
from typing import List
import random
import string
from .. import models, schemas
from ..enums import BookingStatus, FlightStatus, SeatCategory


def create_booking(db: Session, user_id: int, booking_data: schemas.BookingCreate) -> models.Booking:
    # Check if profile is complete
    profile = db.query(models.PassengerProfile).filter(models.PassengerProfile.user_id == user_id).first()
    if not profile or not profile.is_complete:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Profile must be completed before booking"
        )
    
    # Get flight
    flight = db.query(models.Flight).filter(models.Flight.id == booking_data.flight_id).first()
    if not flight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flight not found")
    
    # Check flight status
    if flight.status in [FlightStatus.CANCELLED, FlightStatus.DEPARTED, FlightStatus.LANDED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot book cancelled or departed flights"
        )
    
    # Get seat templates
    seat_templates = db.query(models.SeatTemplate).filter(
        models.SeatTemplate.airplane_id == flight.airplane_id
    ).all()
    seat_template_map = {f"{s.row_number}{s.seat_label}": s for s in seat_templates}
    
    # Get occupied seats
    occupied_seats = get_occupied_seats(db, flight.id)
    
    # Process seat selections
    selected_seats = []
    for passenger in booking_data.passengers:
        if passenger.seat_number:
            # Validate seat exists
            if passenger.seat_number not in seat_template_map:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Seat {passenger.seat_number} does not exist on this aircraft"
                )
            # Check if seat is available
            if passenger.seat_number in occupied_seats:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Seat {passenger.seat_number} is not available"
                )
            selected_seats.append(passenger.seat_number)
        else:
            # Auto-assign seat
            available_seat = None
            for seat_num, template in seat_template_map.items():
                if seat_num not in occupied_seats and seat_num not in selected_seats:
                    available_seat = seat_num
                    break
            if not available_seat:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No available seats"
                )
            selected_seats.append(available_seat)
    
    # Check for duplicate seat selections
    if len(selected_seats) != len(set(selected_seats)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duplicate seat selection"
        )
    
    # Create booking
    pnr = generate_pnr(db)
    total_price = 0
    
    booking = models.Booking(
        pnr=pnr,
        flight_id=flight.id,
        user_id=user_id,
        status=BookingStatus.CREATED,
        total_price=0  # Will update after calculating tickets
    )
    db.add(booking)
    db.flush()  # Get booking ID
    
    # Create tickets and seat holds
    hold_until = datetime.utcnow() + timedelta(minutes=10)
    for i, passenger in enumerate(booking_data.passengers):
        seat_number = selected_seats[i]
        template = seat_template_map[seat_number]
        
        # Calculate price
        price = flight.base_price
        if template.category == SeatCategory.EXTRA_LEGROOM:
            price = flight.base_price * 1.5
        total_price += price
        
        # Create ticket
        ticket_number = generate_ticket_number(db)
        ticket = models.Ticket(
            ticket_number=ticket_number,
            booking_id=booking.id,
            passenger_name=passenger.passenger_name,
            passport_number=passenger.passport_number,
            seat_number=seat_number,
            seat_category=template.category,
            price=price
        )
        db.add(ticket)
        
        # Create seat hold
        seat_hold = models.SeatHold(
            flight_id=flight.id,
            seat_number=seat_number,
            booking_id=booking.id,
            held_until=hold_until
        )
        db.add(seat_hold)
    
    booking.total_price = total_price
    db.commit()
    db.refresh(booking)
    
    return booking


def get_occupied_seats(db: Session, flight_id: int) -> set:
    occupied = set()
    
    # Get confirmed seats
    confirmed_tickets = db.query(models.Ticket).join(models.Booking).filter(
        and_(
            models.Booking.flight_id == flight_id,
            models.Booking.status == BookingStatus.CONFIRMED
        )
    ).all()
    for ticket in confirmed_tickets:
        occupied.add(ticket.seat_number)
    
    # Get held seats (not expired)
    held_seats = db.query(models.SeatHold).filter(
        and_(
            models.SeatHold.flight_id == flight_id,
            models.SeatHold.held_until > datetime.utcnow()
        )
    ).all()
    for hold in held_seats:
        occupied.add(hold.seat_number)
    
    return occupied


def generate_pnr(db: Session) -> str:
    while True:
        pnr = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        existing = db.query(models.Booking).filter(models.Booking.pnr == pnr).first()
        if not existing:
            return pnr


def generate_ticket_number(db: Session) -> str:
    while True:
        ticket_num = ''.join(random.choices(string.digits, k=13))
        existing = db.query(models.Ticket).filter(models.Ticket.ticket_number == ticket_num).first()
        if not existing:
            return ticket_num


def get_booking_by_pnr(db: Session, pnr: str) -> models.Booking:
    booking = db.query(models.Booking).filter(models.Booking.pnr == pnr.upper()).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    return booking


def get_booking(db: Session, booking_id: int) -> models.Booking:
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    return booking

def get_all_bookings(db: Session) -> List[models.Booking]:
    return db.query(models.Booking).order_by(models.Booking.created_at.desc()).all()

def get_user_bookings(db: Session, user_id: int) -> List[models.Booking]:
    return db.query(models.Booking).filter(models.Booking.user_id == user_id).order_by(models.Booking.created_at.desc()).all()


def cancel_booking(db: Session, booking_id: int) -> models.Booking:
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    
    flight = booking.flight
    if flight.status in [FlightStatus.DEPARTED, FlightStatus.LANDED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel booking for departed flights"
        )
    
    # Release seat holds
    db.query(models.SeatHold).filter(models.SeatHold.booking_id == booking_id).delete()
    
    booking.status = BookingStatus.CANCELLED
    db.commit()
    db.refresh(booking)
    
    return booking


def reassign_seat(db: Session, ticket_id: int, new_seat_number: str) -> models.Ticket:
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    booking = ticket.booking
    flight = booking.flight
    
    # Check if new seat exists
    seat_template = db.query(models.SeatTemplate).filter(
        and_(
            models.SeatTemplate.airplane_id == flight.airplane_id,
            models.SeatTemplate.row_number == int(new_seat_number[:-1]),
            models.SeatTemplate.seat_label == new_seat_number[-1]
        )
    ).first()
    
    if not seat_template:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid seat number")
    
    # Check if seat is occupied by another confirmed booking
    existing = db.query(models.Ticket).join(models.Booking).filter(
        and_(
            models.Booking.flight_id == flight.id,
            models.Ticket.seat_number == new_seat_number,
            models.Booking.status == BookingStatus.CONFIRMED,
            models.Ticket.id != ticket_id
        )
    ).first()
    
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Seat already taken")
    
    # Update ticket
    old_seat = ticket.seat_number
    ticket.seat_number = new_seat_number
    ticket.seat_category = seat_template.category
    
    # Calculate new price
    price = flight.base_price
    if seat_template.category == SeatCategory.EXTRA_LEGROOM:
        price = flight.base_price * 1.5
    ticket.price = price
    
    # Update booking total price
    booking.total_price = sum(t.price for t in booking.tickets)
    
    # Update seat hold if exists
    seat_hold = db.query(models.SeatHold).filter(
        and_(
            models.SeatHold.flight_id == flight.id,
            models.SeatHold.seat_number == old_seat,
            models.SeatHold.booking_id == booking.id
        )
    ).first()
    
    if seat_hold:
        seat_hold.seat_number = new_seat_number
    
    db.commit()
    db.refresh(ticket)
    
    return ticket


def get_flight_bookings(db: Session, flight_id: int) -> List[models.Booking]:
    return db.query(models.Booking).filter(models.Booking.flight_id == flight_id).all()

