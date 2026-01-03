"""BookingPassenger model - passenger details captured at booking time.

We persist passenger details (passport/nationality/DOB) per booking, instead of
relying on the mutable user profile.

This is the source of truth for the passenger list attached to a booking.
"""

from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.database import Base


class BookingPassenger(Base):
    # Exam Task naming: Passengers table linked to a booking
    __tablename__ = "passengers"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    booking_id = Column(Integer, ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False, index=True)
    flight_id = Column(Integer, ForeignKey("flights.id", ondelete="CASCADE"), nullable=False, index=True)

    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    seat_number = Column(String(10), nullable=False)

    passport_number = Column(String(20), nullable=False)
    nationality = Column(String(100), nullable=False)
    date_of_birth = Column(Date, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    booking = relationship("Booking", back_populates="passengers")

    __table_args__ = (
        # Prevent duplicate passengers for the same seat within a booking.
        UniqueConstraint("booking_id", "seat_number", name="uq_booking_passenger_seat"),
    )

    def __repr__(self) -> str:
        return (
            f"<BookingPassenger(booking_id={self.booking_id}, seat='{self.seat_number}', "
            f"name='{self.first_name} {self.last_name}')>"
        )
