from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from db.base import Base

class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True)
    flight_id = Column(Integer)
    type = Column(String)  # DELAY, GATE_CHANGE, BOARDING
    title = Column(String)
    message = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
