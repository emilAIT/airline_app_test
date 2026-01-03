from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from .. import schemas
from ..database import get_db
from ..services import staff_service
from ..auth import get_current_passenger

router = APIRouter(prefix="/announcements", tags=["Announcements"])


@router.get("/my-announcements", response_model=List[schemas.AnnouncementResponse])
def get_my_announcements(
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get announcements for user's booked flights"""
    return staff_service.get_user_announcements(db, current_user.id)


@router.get("/flight/{flight_id}", response_model=List[schemas.AnnouncementResponse])
def get_flight_announcements(
    flight_id: int,
    db: Session = Depends(get_db)
):
    """Get announcements for a specific flight"""
    return staff_service.get_flight_announcements(db, flight_id)

