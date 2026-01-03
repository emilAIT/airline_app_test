from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from db.session import get_db
from models.user import User
from core.dependencies import require_staff
from schemas.announcement import AnnouncementCreate, AnnouncementResponse
from services.announcement_service import create_announcement, get_announcements_by_flight

router = APIRouter(prefix="/announcements", tags=["Announcements"])

@router.get("/flight/{flight_id}", response_model=List[AnnouncementResponse])
def get_flight_announcements(
    flight_id: int,
    db: Session = Depends(get_db)
):
    """
    Get all announcements for a specific flight.
    Public endpoint (passengers need to see this).
    """
    return get_announcements_by_flight(db, flight_id)

@router.get("/global", response_model=List[AnnouncementResponse])
def get_global_announcements_endpoint(
    db: Session = Depends(get_db)
):
    """
    Get all global announcements (not specific to a flight).
    """
    from services.announcement_service import get_global_announcements
    return get_global_announcements(db)

@router.post("", response_model=AnnouncementResponse, status_code=status.HTTP_201_CREATED)
def create_new_announcement(
    announcement: AnnouncementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff)
):
    """
    Create a new announcement. 
    Staff only.
    """
    try:
        return create_announcement(db, announcement)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
