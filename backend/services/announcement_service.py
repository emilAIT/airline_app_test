from sqlalchemy.orm import Session
from models.announcement import Announcement
from models.flight import Flight
from schemas.announcement import AnnouncementCreate

def get_announcements_by_flight(db: Session, flight_id: int):
    return db.query(Announcement).filter(Announcement.flight_id == flight_id).all()

def get_global_announcements(db: Session):
    return db.query(Announcement).filter(Announcement.flight_id == None).all()

def create_announcement(db: Session, announcement_data: AnnouncementCreate):
    if announcement_data.flight_id is not None:
        flight = db.query(Flight).filter(Flight.id == announcement_data.flight_id).first()
        if not flight:
            raise ValueError("Flight not found")
        
    announcement = Announcement(
        flight_id=announcement_data.flight_id,
        title=announcement_data.title,
        message=announcement_data.message,
        type=announcement_data.type
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement
