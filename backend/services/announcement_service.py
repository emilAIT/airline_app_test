from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import datetime
from app.models.announcement import Announcement, AnnouncementType
from app.models.flight import Flight


def create_announcement(
    db: Session,
    flight_id: int,
    announcement_type: AnnouncementType,
    message: str
) -> Announcement:
    """
    Create an announcement for a flight (staff only).
    Per instructions.txt lines 236-245.
    """
    # Verify flight exists
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    announcement = Announcement(
        flight_id=flight_id,
        announcement_type=announcement_type,
        message=message
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement


def get_announcements(
    db: Session,
    flight_id: int = None,
    announcement_type: AnnouncementType = None
) -> list:
    """
    Get announcements, optionally filtered by flight or type.
    Visible to passengers per instructions.txt line 245.
    """
    query = db.query(Announcement)
    
    if flight_id:
        query = query.filter(Announcement.flight_id == flight_id)
    
    if announcement_type:
        query = query.filter(Announcement.announcement_type == announcement_type)
    
    return query.order_by(Announcement.created_at.desc()).all()


def get_announcement(db: Session, announcement_id: int) -> Announcement:
    """Get a single announcement"""
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Announcement not found"
        )
    return announcement


def delete_announcement(db: Session, announcement_id: int) -> dict:
    """Delete an announcement (staff only)"""
    announcement = get_announcement(db, announcement_id)
    db.delete(announcement)
    db.commit()
    return {"message": "Announcement deleted successfully"}
