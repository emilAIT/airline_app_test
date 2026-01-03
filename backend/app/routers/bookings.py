from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import schemas
from ..database import get_db
from ..services import booking_service
from ..auth import get_current_passenger

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("/", response_model=schemas.BookingResponse, status_code=status.HTTP_201_CREATED)
def create_booking(
    booking_data: schemas.BookingCreate,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Create a new booking with seat selection"""
    return booking_service.create_booking(db, current_user.id, booking_data)


@router.get("/my-bookings", response_model=List[schemas.BookingDetailResponse])
def get_my_bookings(
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get all bookings for current user"""
    bookings = booking_service.get_user_bookings(db, current_user.id)
    return bookings


@router.get("/{pnr}", response_model=schemas.BookingDetailResponse)
def get_booking_by_pnr(
    pnr: str,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get booking by PNR code"""
    booking = booking_service.get_booking_by_pnr(db, pnr)
    
    # Verify booking belongs to user
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    return booking


@router.post("/{booking_id}/cancel", response_model=schemas.BookingResponse)
def cancel_booking(
    booking_id: int,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Cancel a booking"""
    booking = booking_service.get_booking(db, booking_id)
    
    # Verify booking belongs to user
    if booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    return booking_service.cancel_booking(db, booking_id)

