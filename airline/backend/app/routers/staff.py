from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_staff_user
from app.models.all_models import User, Airplane, Flight, Booking, Announcement, FlightStatus, Airport
from app.schemas.schemas import (
    AirplaneCreate, AirplaneOut, FlightCreate, FlightUpdate, FlightOut,
    AnnouncementCreate, AnnouncementOut, BookingOut, AirportCreate, AirportOut
)
from typing import List, Optional
import json

router = APIRouter(prefix="/staff", tags=["Staff"])

# --- AIRPORTS ---


@router.post("/airports", response_model=AirportOut, status_code=status.HTTP_201_CREATED)
@router.post("/airports/", response_model=AirportOut, status_code=status.HTTP_201_CREATED)
def create_airport(
    airport_data: AirportCreate,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Create a new airport"""
    # Check if airport with same code already exists
    existing = db.query(Airport).filter(
        Airport.code == airport_data.code.upper()).first()
    if existing:
        raise HTTPException(
            status_code=400, detail=f"Airport with code {airport_data.code} already exists")

    airport = Airport(
        code=airport_data.code.upper(),
        name=airport_data.name,
        city=airport_data.city,
        country=airport_data.country
    )
    db.add(airport)
    db.commit()
    db.refresh(airport)
    return airport


@router.get("/airports", response_model=List[AirportOut])
def get_airports_staff(
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get all airports (staff view)"""
    airports = db.query(Airport).all()
    return airports

# --- AIRPLANES ---


@router.post("/airplanes", response_model=AirplaneOut, status_code=status.HTTP_201_CREATED)
@router.post("/airplanes/", response_model=AirplaneOut, status_code=status.HTTP_201_CREATED)
def create_airplane(
    airplane_data: AirplaneCreate,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Create a new airplane model with seat configuration"""
    seat_config_json = json.dumps(airplane_data.seat_config.model_dump())

    airplane = Airplane(
        model=airplane_data.model,
        total_seats=airplane_data.total_seats,
        seat_config=seat_config_json
    )
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    return airplane


@router.get("/airplanes", response_model=List[AirplaneOut])
def get_airplanes(
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get all airplanes"""
    airplanes = db.query(Airplane).all()
    return airplanes


@router.get("/airplanes/{airplane_id}", response_model=AirplaneOut)
def get_airplane(
    airplane_id: int,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get airplane details"""
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(status_code=404, detail="Airplane not found")
    return airplane

# --- FLIGHTS ---


@router.post("/flights", response_model=FlightOut, status_code=status.HTTP_201_CREATED)
@router.post("/flights/", response_model=FlightOut, status_code=status.HTTP_201_CREATED)
def create_flight(
    flight_data: FlightCreate,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Create a new flight"""
    try:
        # Validate that airports and airplane exist
        from app.models.all_models import Airport, Airplane
        origin = db.query(Airport).filter(
            Airport.id == flight_data.origin_id).first()
        if not origin:
            raise HTTPException(
                status_code=404, detail=f"Origin airport with id {flight_data.origin_id} not found")

        destination = db.query(Airport).filter(
            Airport.id == flight_data.destination_id).first()
        if not destination:
            raise HTTPException(
                status_code=404, detail=f"Destination airport with id {flight_data.destination_id} not found")

        airplane = db.query(Airplane).filter(
            Airplane.id == flight_data.airplane_id).first()
        if not airplane:
            raise HTTPException(
                status_code=404, detail=f"Airplane with id {flight_data.airplane_id} not found")

        # Check if flight number already exists
        existing = db.query(Flight).filter(
            Flight.flight_number == flight_data.flight_number).first()
        if existing:
            raise HTTPException(
                status_code=400, detail=f"Flight number {flight_data.flight_number} already exists")

        flight = Flight(**flight_data.model_dump())
        db.add(flight)
        db.commit()
        db.refresh(flight)

        # Generate seats for the flight
        from app.services.seat_service import generate_seats_for_flight
        try:
            generate_seats_for_flight(db, flight)
        except Exception as e:
            # Rollback flight creation if seat generation fails
            db.rollback()
            raise HTTPException(
                status_code=500, detail=f"Failed to generate seats: {str(e)}")

        return flight
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500, detail=f"Error creating flight: {str(e)}")


@router.put("/flights/{flight_id}", response_model=FlightOut)
@router.put("/flights/{flight_id}/", response_model=FlightOut)
def update_flight(
    flight_id: int,
    flight_data: FlightUpdate,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Update flight details"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    update_data = flight_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(flight, field, value)

    db.commit()
    db.refresh(flight)
    return flight


@router.get("/flights", response_model=List[FlightOut])
def get_all_flights(
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get all flights (staff view)"""
    flights = db.query(Flight).order_by(Flight.departure_time).all()
    return flights

# --- BOOKINGS ---


@router.get("/bookings", response_model=List[BookingOut])
def get_all_bookings(
    flight_id: Optional[int] = Query(None),
    pnr: Optional[str] = Query(None),
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get all bookings with optional filters"""
    query = db.query(Booking)

    if flight_id:
        query = query.filter(Booking.flight_id == flight_id)
    if pnr:
        query = query.filter(Booking.pnr == pnr)

    bookings = query.order_by(Booking.created_at.desc()).all()
    return bookings


@router.get("/bookings/{booking_id}", response_model=BookingOut)
def get_booking(
    booking_id: int,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get booking details"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@router.delete("/bookings/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
@router.delete("/bookings/{booking_id}/", status_code=status.HTTP_204_NO_CONTENT)
def cancel_booking_staff(
    booking_id: int,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Cancel a booking (staff)"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.flight.status == FlightStatus.DEPARTED:
        raise HTTPException(
            status_code=400, detail="Cannot cancel booking for departed flight")

    from app.services.booking_service import cancel_booking
    try:
        cancel_booking(db, booking_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return None


@router.put("/bookings/{booking_id}/reassign-seat")
def reassign_seat(
    booking_id: int,
    ticket_id: int,
    new_seat: str,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Reassign a seat for a ticket (staff override)"""
    from app.models.all_models import Ticket, Seat
    from app.services.seat_service import is_seat_available, mark_seat_unavailable

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    ticket = db.query(Ticket).filter(Ticket.id == ticket_id,
                                     Ticket.booking_id == booking_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # Check if new seat is available
    if not is_seat_available(db, booking.flight_id, new_seat):
        raise HTTPException(
            status_code=400, detail=f"Seat {new_seat} is not available")

    # Release old seat
    old_seat = db.query(Seat).filter(
        Seat.flight_id == booking.flight_id,
        Seat.seat_number == ticket.seat_number
    ).first()
    if old_seat:
        old_seat.is_available = True

    # Assign new seat
    ticket.seat_number = new_seat
    mark_seat_unavailable(db, booking.flight_id, new_seat)

    db.commit()
    return {"message": f"Seat reassigned to {new_seat}"}

# --- ANNOUNCEMENTS ---


@router.post("/announcements", response_model=AnnouncementOut, status_code=status.HTTP_201_CREATED)
@router.post("/announcements/", response_model=AnnouncementOut, status_code=status.HTTP_201_CREATED)
def create_announcement(
    announcement_data: AnnouncementCreate,
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Create an announcement"""
    announcement = Announcement(**announcement_data.model_dump())
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement


@router.get("/announcements", response_model=List[AnnouncementOut])
def get_announcements(
    flight_id: Optional[int] = Query(None),
    current_user: User = Depends(get_current_staff_user),
    db: Session = Depends(get_db)
):
    """Get all announcements"""
    query = db.query(Announcement)
    if flight_id:
        query = query.filter(Announcement.flight_id == flight_id)
    announcements = query.order_by(Announcement.created_at.desc()).all()
    return announcements
