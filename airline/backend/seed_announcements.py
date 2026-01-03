from datetime import datetime, timedelta
from app.database import SessionLocal
from app.models.all_models import Announcement, Flight
from app.schemas.schemas import AnnouncementType

def seed_announcements():
    db = SessionLocal()
    
    try:
        print("Seeding announcements...")
        
        # 1. Global Announcement
        global_announcement = Announcement(
            title="Welcome to ELDIK AirLines",
            message="We are delighted to have you on board. Please check your flight status for recent updates.",
            type=AnnouncementType.INFO,
            created_at=datetime.utcnow()
        )
        db.add(global_announcement)
        
        # 2. Get some upcoming flights to attach announcements to
        flights = db.query(Flight).filter(Flight.departure_time > datetime.utcnow()).limit(3).all()
        
        if flights:
            # Flight 1: Boarding soon
            if len(flights) > 0:
                f1 = flights[0]
                a1 = Announcement(
                    flight_id=f1.id,
                    title="Boarding Starting Soon",
                    message=f"Passenger boarding for flight {f1.flight_number} to {f1.destination.city} will begin in 20 minutes.",
                    type=AnnouncementType.BOARDING_STARTED,
                    created_at=datetime.utcnow()
                )
                db.add(a1)
                
            # Flight 2: Gate Change
            if len(flights) > 1:
                f2 = flights[1]
                a2 = Announcement(
                    flight_id=f2.id,
                    title="Gate Change",
                    message=f"Attention passengers of flight {f2.flight_number}. The departure gate has changed to Gate {f2.gate or 'B12'}.",
                    type=AnnouncementType.GATE_CHANGE,
                    created_at=datetime.utcnow() - timedelta(minutes=30)
                )
                db.add(a2)
                
            # Flight 3: Delay
            if len(flights) > 2:
                f3 = flights[2]
                a3 = Announcement(
                    flight_id=f3.id,
                    title="Flight Delayed",
                    message=f"Flight {f3.flight_number} is delayed by 45 minutes due to weather conditions at {f3.destination.city}.",
                    type=AnnouncementType.DELAY,
                    created_at=datetime.utcnow() - timedelta(hours=1)
                )
                db.add(a3)

        db.commit()
        print("Announcements seeded successfully!")
        
    except Exception as e:
        print(f"Error seeding announcements: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_announcements()
