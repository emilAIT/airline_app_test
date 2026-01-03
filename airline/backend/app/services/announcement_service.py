from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List
from app.models.announcement import Announcement
from app.models.flight import Flight
from app.schemas.announcement import AnnouncementCreate


def create_announcement(
    db: Session,
    announcement_data: AnnouncementCreate,
    created_by: int
) -> Announcement:
    # Проверяем, что рейс существует (если указан)
    if announcement_data.flight_id is not None:
        flight = db.query(Flight).filter(Flight.id == announcement_data.flight_id).first()
        if not flight:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Рейс не найден"
            )
    
    announcement = Announcement(
        **announcement_data.model_dump(),
        created_by=created_by
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement


def get_flight_announcements(db: Session, flight_id: int) -> List[Announcement]:
    announcements = db.query(Announcement).filter(
        Announcement.flight_id == flight_id
    ).order_by(Announcement.created_at.desc()).all()
    return announcements


def get_announcement_by_id(db: Session, announcement_id: int) -> Announcement:
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Объявление не найдено"
        )
    return announcement


def delete_announcement(db: Session, announcement_id: int) -> None:
    announcement = get_announcement_by_id(db, announcement_id)
    db.delete(announcement)
    db.commit()



