"""
Announcements API routes.

Endpoints:
- GET /my-flights: Get announcements for user's booked flights
- GET /flight/{flight_id}: Get announcements for specific flight

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_passenger
from app.models.user import User
from app.models.booking import Booking
from app.schemas.announcement import AnnouncementResponse
from app.api.routes.staff import update_flight_status_based_on_time

router = APIRouter(prefix="/announcements", tags=["Announcements"])


@router.get("/my-flights", response_model=List[AnnouncementResponse])
def get_my_announcements(
    current_user: User = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get announcements for user's flights"""
    # Get user's bookings
    bookings = db.query(Booking).filter(Booking.user_id == current_user.id).all()
    
    # Trigger auto-status updates
    updates = False
    for booking in bookings:
        if booking.flight and update_flight_status_based_on_time(booking.flight, db):
            updates = True
    if updates:
        db.commit()

    flight_ids = [booking.flight_id for booking in bookings]
    
    # Get announcements for these flights OR general announcements
    from app.models.announcement import Announcement
    from sqlalchemy import or_
    
    query = db.query(Announcement)
    
    if flight_ids:
        query = query.filter(
            or_(
                Announcement.flight_id.in_(flight_ids),
                Announcement.flight_id.is_(None)
            )
        )
    else:
        query = query.filter(Announcement.flight_id.is_(None))
        
    announcements = query.order_by(Announcement.created_at.desc()).all()
    
    return announcements


@router.get("/flight/{flight_id}", response_model=List[AnnouncementResponse])
def get_flight_announcements(
    flight_id: int,
    db: Session = Depends(get_db)
):
    """Get announcements for a specific flight"""
    from app.models.announcement import Announcement
    announcements = db.query(Announcement).filter(
        Announcement.flight_id == flight_id
    ).order_by(Announcement.created_at.desc()).all()
    
    return announcements

