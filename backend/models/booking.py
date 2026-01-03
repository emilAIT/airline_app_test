import uuid
import string
import random
import enum
from datetime import datetime

from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Enum
)
from sqlalchemy.orm import relationship, Session

from db.base import Base


class BookingStatus(str, enum.Enum):
    CREATED = "CREATED"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)

    pnr_code = Column(String, unique=True, index=True, nullable=False)

    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    user_id = Column(Integer, nullable=True)

    status = Column(
        Enum(BookingStatus),
        default=BookingStatus.CREATED,
        nullable=False
    )

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # 🔗 Relations
    flight = relationship("Flight")
    tickets = relationship(
        "Ticket",
        back_populates="booking",
        cascade="all, delete-orphan"
    )

    # ---------- UTILS ----------

    @staticmethod
    def _generate_pnr() -> str:
        chars = string.ascii_uppercase + string.digits
        return "".join(random.choices(chars, k=6))

    @classmethod
    def generate_unique_pnr(cls, db: Session) -> str:
        while True:
            pnr = cls._generate_pnr()
            exists = db.query(cls).filter_by(pnr_code=pnr).first()
            if not exists:
                return pnr

    # ---------- BUSINESS LOGIC ----------

    @classmethod
    def create_booking(
        cls,
        db: Session,
        flight,
        ticket_data: list[dict],
        user_id: int = None
    ):
        # 1. Проверка рейса
        if flight.status in ["CANCELLED", "LANDED"]:
            raise ValueError("Cannot book a cancelled or finished flight")

        if flight.departure_time < datetime.utcnow():
            raise ValueError("Flight has already departed")

        # 2. Проверка занятых мест
        requested_seats = {t["seat_number"] for t in ticket_data}
        occupied_seats = {t.seat_number for t in flight.tickets}

        conflict = requested_seats & occupied_seats
        if conflict:
            raise ValueError(f"Seats already booked: {', '.join(conflict)}")

        # 3. Создание бронирования (транзакционно)
        from models.ticket import Ticket  # избегаем circular import

        booking = cls(
            pnr_code=cls.generate_unique_pnr(db),
            flight_id=flight.id,
            user_id=user_id,
            status=BookingStatus.CREATED
        )
        db.add(booking)
        db.flush()

        for data in ticket_data:
            db.add(
                Ticket(
                    booking_id=booking.id,
                    flight_id=flight.id,
                    passenger_name=data["passenger_name"],
                    passport_number=data.get("passport_number"),
                    nationality=data.get("nationality"),
                    seat_number=data["seat_number"],
                    ticket_number=f"TKT-{uuid.uuid4().hex[:8].upper()}"
                )
            )
        
        db.commit()
        db.refresh(booking)
        return booking

    def confirm_payment(self, db: Session):
        self.status = BookingStatus.CONFIRMED
        db.commit()
        db.refresh(self)
        return self