"""Flight model (exam schema)."""

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship

from app.database import Base


class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    flight_number = Column(String(10), unique=True, nullable=False, index=True)

    origin_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    destination_id = Column(Integer, ForeignKey("airports.id"), nullable=False)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=True)

    departure_time = Column(DateTime(timezone=True), nullable=False, index=True)
    arrival_time = Column(DateTime(timezone=True), nullable=False)

    # Optional UI fields (terminal/gate)
    terminal = Column(String(10), nullable=True)
    gate = Column(String(10), nullable=True)

    price = Column(Numeric(10, 2), nullable=False)
    status = Column(String(20), nullable=False, default="SCHEDULED", index=True)

    origin = relationship("Airport", foreign_keys=[origin_id], lazy="joined")
    destination = relationship("Airport", foreign_keys=[destination_id], lazy="joined")
    airplane = relationship("Airplane", foreign_keys=[airplane_id], lazy="select")
    bookings = relationship("Booking", back_populates="flight")
    seat_holds = relationship("SeatHold", back_populates="flight", cascade="all, delete-orphan")
    announcements = relationship("Announcement", back_populates="flight", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint("price >= 0", name="check_price_positive"),
        CheckConstraint("origin_id != destination_id", name="check_different_airports"),
    )

    def __repr__(self) -> str:
        return f"<Flight(number='{self.flight_number}', status='{self.status}')>"
