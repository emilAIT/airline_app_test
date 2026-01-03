from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_user
from app.models.all_models import User, Announcement, Booking, UserRole
from app.schemas.schemas import AnnouncementOut
from typing import List, Optional

router = APIRouter(prefix="/announcements", tags=["Announcements"])


@router.get("/", response_model=List[AnnouncementOut])
@router.get("", response_model=List[AnnouncementOut])
def get_announcements(
    flight_id: Optional[int] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get announcements for current user's flights or all announcements"""
    if current_user.role == UserRole.PASSENGER:
        # Get announcements for user's booked flights
        user_bookings = db.query(Booking).filter(Booking.user_id == current_user.id).all()
        user_flight_ids = {booking.flight_id for booking in user_bookings}

        if flight_id:
            # Check if user has booking for this flight
            if flight_id not in user_flight_ids:
                return []
            announcements = db.query(Announcement).filter(
                Announcement.flight_id == flight_id
            ).order_by(Announcement.created_at.desc()).all()
        else:
            # Get announcements for all user's flights + global announcements
            announcements = db.query(Announcement).filter(
                (Announcement.flight_id.in_(user_flight_ids)) | (Announcement.flight_id.is_(None))
            ).order_by(Announcement.created_at.desc()).all()
    else:
        # Staff can see all announcements
        if flight_id:
            announcements = db.query(Announcement).filter(
                Announcement.flight_id == flight_id
            ).order_by(Announcement.created_at.desc()).all()
        else:
            announcements = db.query(Announcement).order_by(Announcement.created_at.desc()).all()

    return announcements

