from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import schemas
from ..database import get_db
from ..services import staff_service, booking_service
from ..auth import get_current_staff

router = APIRouter(prefix="/staff", tags=["Staff"])


# Airplane Management
@router.post("/airplanes", response_model=schemas.AirplaneResponse, status_code=status.HTTP_201_CREATED)
def create_airplane(
    airplane_data: schemas.AirplaneCreate,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a new airplane with seat template"""
    return staff_service.create_airplane(db, airplane_data)


@router.get("/airplanes", response_model=List[schemas.AirplaneResponse])
def get_airplanes(
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all airplanes"""
    return staff_service.get_all_airplanes(db)


@router.get("/airplanes/{airplane_id}", response_model=schemas.AirplaneDetailResponse)
def get_airplane(
    airplane_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get airplane details including seat template"""
    return staff_service.get_airplane_detail(db, airplane_id)


@router.patch("/airplanes/{airplane_id}", response_model=schemas.AirplaneDetailResponse)
def update_airplane(
    airplane_id: int,
    airplane_data: schemas.AirplaneUpdate,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Update airplane details"""
    return staff_service.update_airplane(db, airplane_id, airplane_data)


# Flight Management
@router.post("/flights", response_model=schemas.FlightDetailResponse, status_code=status.HTTP_201_CREATED)
def create_flight(
    flight_data: schemas.FlightCreate,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a new flight"""
    return staff_service.create_flight(db, flight_data)


@router.get("/flights", response_model=List[schemas.FlightDetailResponse])
def get_all_flights(
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all flights"""
    return staff_service.get_all_flights(db)


@router.get("/flights/{flight_id}", response_model=schemas.FlightDetailResponse)
def get_flight(
    flight_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get flight details by ID"""
    return staff_service.get_flight_detail(db, flight_id)


@router.put("/flights/{flight_id}", response_model=schemas.FlightDetailResponse)
def update_flight(
    flight_id: int,
    flight_data: schemas.FlightUpdate,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Update flight details"""
    return staff_service.update_flight(db, flight_id, flight_data)


@router.delete("/flights/{flight_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_flight(
    flight_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete a flight"""
    staff_service.delete_flight(db, flight_id)
    return None


# Announcement Management
@router.post("/announcements", response_model=schemas.AnnouncementResponse, status_code=status.HTTP_201_CREATED)
def create_announcement(
    announcement_data: schemas.AnnouncementCreate,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a flight announcement"""
    return staff_service.create_announcement(db, announcement_data)


@router.get("/announcements", response_model=List[schemas.AnnouncementResponse])
def get_all_announcements(
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all announcements"""
    return staff_service.get_all_announcements(db)


@router.delete("/announcements/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_announcement(
    announcement_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete an announcement"""
    staff_service.delete_announcement(db, announcement_id)
    return None


# Booking Management
@router.get("/bookings", response_model=List[schemas.BookingDetailResponse])
def get_all_bookings(
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all bookings"""
    return booking_service.get_all_bookings(db)


@router.get("/bookings/flight/{flight_id}", response_model=List[schemas.BookingDetailResponse])
def get_flight_bookings(
    flight_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all bookings for a flight"""
    return booking_service.get_flight_bookings(db, flight_id)


@router.get("/bookings/{pnr}", response_model=schemas.BookingDetailResponse)
def search_booking(
    pnr: str,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Search booking by PNR"""
    return booking_service.get_booking_by_pnr(db, pnr)


@router.post("/bookings/{booking_id}/cancel", response_model=schemas.BookingResponse)
def cancel_booking(
    booking_id: int,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Cancel a booking (staff override)"""
    return booking_service.cancel_booking(db, booking_id)


@router.post("/bookings/reassign-seat", response_model=schemas.TicketResponse)
def reassign_seat(
    reassign_data: schemas.SeatReassign,
    current_user = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Reassign seat for a ticket"""
    return booking_service.reassign_seat(db, reassign_data.ticket_id, reassign_data.new_seat_number)

