from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship, Session
from models.seat_hold import SeatHold # keep import but remove global relationship

from db.base import Base

class Flight(Base):
    __tablename__ = "flights"

    id = Column(Integer, primary_key=True, index=True)

    flight_number = Column(String, unique=True, nullable=False)

    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=True)

    departure_time = Column(DateTime, nullable=False)
    arrival_time = Column(DateTime, nullable=False)

    gate = Column(String, nullable=True)
    terminal = Column(String, nullable=True)

    price = Column(Float, nullable=False)

    total_seats = Column(Integer, nullable=False, default=180)

    origin_code = Column(
        String(3),
        ForeignKey("airports.code"),
        nullable=False
    )

    destination_code = Column(
        String(3),
        ForeignKey("airports.code"),
        nullable=False
    )

    # 🔗 связи с Airport
    origin = relationship(
        "Airport",
        foreign_keys=[origin_code],
        back_populates="departures"
    )

    destination = relationship(
        "Airport",
        foreign_keys=[destination_code],
        back_populates="arrivals"
    )

    tickets = relationship( #################
        "Ticket",
        back_populates="flight",
        cascade="all, delete-orphan"
    )

    seat_holds = relationship(
        "SeatHold",
        cascade="all, delete-orphan"
    )


    status = Column(
        String,
        default="SCHEDULED"
    )  # SCHEDULED, BOARDING, DELAYED, CANCELLED, LANDED

    airplane = relationship(
        "Airplane",
        back_populates="flights"
    )
    

    @classmethod
    def search(
        cls,
        db: Session,
        origin_code: str,
        destination_code: str,
        departure_date: datetime
    ):
        start = departure_date.replace(hour=0, minute=0, second=0)
        end = departure_date.replace(hour=23, minute=59, second=59)

        return (
            db.query(cls)
            .filter(
                cls.origin_code == origin_code.upper(),
                cls.destination_code == destination_code.upper(),
                cls.departure_time >= start,
                cls.departure_time <= end
            )
            .all()
        )


    # @classmethod
    # def create_flight(
    #     cls,
    #     db: Session,
    # #     flight_number: str,
    #     origin_code: str,
    #     destination_code: str,
    #     departure_time,
    #     arrival_time,
    #     price: float
    # ):
    #     flight = cls(
    #         flight_number=flight_number,
    #         origin_code=origin_code,
    #         destination_code=destination_code,
    #         departure_time=departure_time,
    #         arrival_time=arrival_time,
    #         price=price,
    #         status="SCHEDULED"
    #     )

    #     db.add(flight)
    #     db.commit()
    #     db.refresh(flight)
    #     return flight

    # def assign_airplane(self, db: Session, airplane_id: int):
    #     self.airplane_id = airplane_id
    #     db.commit()
    #     db.refresh(self)
    #     return self

    # def update_schedule(
    #     self,
    #     db: Session,
    #     departure_time=None,
    #     arrival_time=None
    # ):
    #     if departure_time:
    #         self.departure_time = departure_time
    #     if arrival_time:
    #         self.arrival_time = arrival_time

    #     db.commit()
    #     db.refresh(self)
    #     return self

    # def update_gate(self, db: Session, gate: str):
    #     self.gate = gate
    #     db.commit()
    #     db.refresh(self)
    #     return self

    # def update_terminal(self, db: Session, terminal: str):
    #     self.terminal = terminal
    #     db.commit()
    #     db.refresh(self)
    #     return self

    # def update_status(self, db: Session, status: str):
    #     allowed_statuses = [
    #         "SCHEDULED",
    #         "BOARDING",
    #         "DELAYED",
    #         "CANCELLED",
    #         "LANDED"
    #     ]

    #     if status not in allowed_statuses:
    #         raise ValueError("Invalid flight status")

    #     self.status = status
    #     db.commit()
    #     db.refresh(self)
    #     return self
    
    # @property
    # def duration_minutes(self) -> int:
    #     if not self.departure_time or not self.arrival_time:
    #         return 0
    #     delta = self.arrival_time - self.departure_time
    #     return int(delta.total_seconds() // 60)