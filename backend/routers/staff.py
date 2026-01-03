from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.dependencies import get_current_staff
from app.models.user import User
from app.schemas.airplane import AirplaneCreate
from app.schemas.flight import FlightCreate
from app.schemas.announcement import AnnouncementCreate
from app.services import airplane_service, flight_service, announcement_service, booking_service

router = APIRouter(prefix="/staff", tags=["Staff"])


# Airplane Management
@router.post("/airplanes", status_code=status.HTTP_201_CREATED)
def create_airplane_endpoint(
    airplane_data: AirplaneCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Create a new airplane with seat template"""
    return airplane_service.create_airplane(
        db,
        model=airplane_data.model,
        registration_number=airplane_data.registration_number,
        seat_template=airplane_data.seat_template,
        total_seats=airplane_data.total_seats
    )


@router.get("/airplanes")
def list_airplanes_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """List all airplanes"""
    return airplane_service.list_airplanes(db)


@router.get("/airplanes/{airplane_id}")
def get_airplane_endpoint(
    airplane_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Get airplane details"""
    return airplane_service.get_airplane(db, airplane_id)


@router.delete("/airplanes/{airplane_id}")
def delete_airplane_endpoint(
    airplane_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Delete an airplane"""
    airplane = airplane_service.get_airplane(db, airplane_id)
    db.delete(airplane)
    db.commit()
    return {"message": "Airplane deleted successfully"}


# Flight Management
@router.post("/flights", status_code=status.HTTP_201_CREATED)
def create_flight_endpoint(
    flight_data: FlightCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Create a new flight"""
    return flight_service.create_flight(
        db,
        flight_number=flight_data.flight_number,
        origin_id=flight_data.origin_id,
        destination_id=flight_data.destination_id,
        airplane_id=flight_data.airplane_id,
        scheduled_departure=flight_data.scheduled_departure,
        scheduled_arrival=flight_data.scheduled_arrival,
        price=flight_data.price,
        gate=flight_data.gate,
        terminal=flight_data.terminal
    )


@router.get("/flights")
def list_flights_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """List all flights"""
    return flight_service.list_flights(db)


@router.get("/flights/{flight_id}")
def get_flight_endpoint(
    flight_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Get flight details"""
    return flight_service.get_flight(db, flight_id)


@router.put("/flights/{flight_id}")
def update_flight_endpoint(
    flight_id: int,
    update_data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Update flight details (supports partial updates)"""
    return flight_service.update_flight(db, flight_id, update_data)


@router.put("/flights/{flight_id}/status")
def update_flight_status_endpoint(
    flight_id: int,
    status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Update flight status"""
    from app.models.flight import FlightStatus
    try:
        flight_status = FlightStatus(status)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid flight status. Must be one of: {[s.value for s in FlightStatus]}"
        )
    
    return flight_service.update_flight_status(db, flight_id, flight_status)


# Announcement Management
@router.post("/announcements", status_code=status.HTTP_201_CREATED)
def create_announcement_endpoint(
    announcement_data: AnnouncementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """
    Publish an announcement for a flight.
    Per instructions.txt lines 236-245.
    """
    return announcement_service.create_announcement(
        db,
        flight_id=announcement_data.flight_id,
        announcement_type=announcement_data.announcement_type,
        message=announcement_data.message
    )


@router.get("/announcements")
def list_announcements_endpoint(
    flight_id: int = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """List announcements, optionally filtered by flight"""
    return announcement_service.get_announcements(db, flight_id=flight_id)


@router.delete("/announcements/{announcement_id}")
def delete_announcement_endpoint(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """Delete an announcement"""
    return announcement_service.delete_announcement(db, announcement_id)


# Booking Management
@router.get("/bookings")
def list_bookings_endpoint(
    flight_id: int = None,
    pnr: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """List all bookings, optionally filtered by flight or PNR"""
    if pnr:
        # Search by PNR
        from app.models.booking import Booking
        booking = db.query(Booking).filter(Booking.pnr == pnr.upper()).first()
        if not booking:
            return []
        bookings = [booking]
    else:
        bookings = booking_service.list_bookings(db, flight_id=flight_id)
    
    # Serialize bookings with tickets
    return [
        {
            "id": booking.id,
            "pnr": booking.pnr,
            "user_id": booking.user_id,
            "flight_id": booking.flight_id,
            "status": booking.status.value,
            "held_until": booking.held_until.isoformat() if booking.held_until else None,
            "created_at": booking.created_at.isoformat(),
            "passenger_name": f"{booking.user.passenger_profile.first_name} {booking.user.passenger_profile.last_name}" 
                if booking.user and booking.user.passenger_profile else "N/A",
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


@router.delete("/bookings/{booking_id}")
def cancel_booking_endpoint(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """
    Cancel a booking (staff override).
    Only before departure per instructions.txt line 166.
    """
    return booking_service.cancel_booking(db, booking_id)


@router.put("/bookings/{booking_id}/tickets/{ticket_id}/seat")
def reassign_seat_endpoint(
    booking_id: int,
    ticket_id: int,
    new_seat: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff)
):
    """
    Reassign a seat for a ticket.
    Staff can override per instructions.txt line 165.
    """
    ticket = booking_service.reassign_seat(db, booking_id, ticket_id, new_seat)
    return {
        "message": "Seat reassigned successfully",
        "ticket": ticket
    }
