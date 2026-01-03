from sqlalchemy import Column, Integer, String, Boolean, DateTime
from datetime import datetime
from db.base import Base

class CheckIn(Base):
    __tablename__ = "checkins"

    id = Column(Integer, primary_key=True)
    ticket_id = Column(Integer)
    boarding_pass_qr = Column(String)
    checked_in = Column(Boolean, default=False)
    checked_in_at = Column(DateTime, default=datetime.utcnow)
