"""
Announcements API - public flight announcements.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from app.core.dependencies import get_db, get_current_user
from app.models.announcement import Announcement
from app.models.booking import Booking
from app.models.user import User


router = APIRouter()


class AnnouncementResponse(BaseModel):
    """Announcement response schema."""
    id: int
    flight_id: Optional[int] = None
    message: str
    announcement_type: str
    created_at: str
    
    class Config:
        from_attributes = True


@router.get("/my", response_model=List[AnnouncementResponse])
def get_my_announcements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get announcements for passenger's booked flights.
    
    Logic:
    - Get all flight_ids from user's confirmed bookings
    - Return announcements for those flights
    - Also return general announcements (flight_id = NULL)
    - If user has no bookings, only show general announcements
    
    Returns announcements in reverse chronological order (newest first).
    """
    # Get all flight IDs from user's confirmed bookings
    bookings = db.query(Booking).filter(
        Booking.user_id == current_user.id,
        Booking.status == "CONFIRMED"
    ).all()
    
    flight_ids = [b.flight_id for b in bookings]
    
    # Get announcements for user's flights OR general announcements (flight_id = NULL)
    if flight_ids:
        announcements = db.query(Announcement).filter(
            (Announcement.flight_id.in_(flight_ids)) |
            (Announcement.flight_id == None)
        ).order_by(Announcement.created_at.desc()).all()
    else:
        # User has no bookings - only show general announcements
        announcements = db.query(Announcement).filter(
            Announcement.flight_id == None
        ).order_by(Announcement.created_at.desc()).all()
    
    return [
        AnnouncementResponse(
            id=a.id,
            flight_id=a.flight_id,
            message=a.message,
            announcement_type=a.announcement_type,
            created_at=a.created_at.isoformat()
        )
        for a in announcements
    ]


@router.get("/flight/{flight_id}", response_model=List[AnnouncementResponse])
def get_flight_announcements(
    flight_id: int,
    db: Session = Depends(get_db)
):
    """
    Get all announcements for a flight (public endpoint).
    
    Returns announcements in reverse chronological order (newest first).
    
    Types:
        - INFO: General information
        - DELAY: Flight delayed
        - GATE_CHANGE: Gate changed
        - CANCELLATION: Flight cancelled
    """
    announcements = db.query(Announcement).filter(
        Announcement.flight_id == flight_id
    ).order_by(Announcement.created_at.desc()).all()
    
    return [
        AnnouncementResponse(
            id=a.id,
            flight_id=a.flight_id,
            message=a.message,
            announcement_type=a.announcement_type,
            created_at=a.created_at.isoformat()
        )
        for a in announcements
    ]
