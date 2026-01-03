from datetime import datetime, timedelta
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from db.base import Base


class SeatHold(Base):
    __tablename__ = "seat_holds"

    id = Column(Integer, primary_key=True)

    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    seat_number = Column(String, nullable=False)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    expires_at = Column(DateTime, nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow)

    # 🔗 relations
    flight = relationship("Flight")
    user = relationship("User")

    @staticmethod
    def hold_for_10_minutes():
        return datetime.utcnow() + timedelta(minutes=10)

    def is_expired(self) -> bool:
        return self.expires_at < datetime.utcnow()
