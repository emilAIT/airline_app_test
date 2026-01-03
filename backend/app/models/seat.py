"""Seat model - physical seats in airplanes.

Fields:
  - id
  - airplane_id (FK to airplanes)
  - row_number (1, 2, 3, ...)
  - seat_letter (A, B, C, D, E, F)
  - category: 'standard' or 'extra_legroom'
"""

from sqlalchemy import Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class Seat(Base):
    __tablename__ = "seats"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    airplane_id = Column(Integer, ForeignKey("airplanes.id", ondelete="CASCADE"), nullable=False, index=True)
    row_number = Column(Integer, nullable=False)
    seat_letter = Column(String(1), nullable=False)
    category = Column(String(20), nullable=False, default='standard')  # 'standard' or 'extra_legroom'

    # Relationships
    airplane = relationship("Airplane", back_populates="seats")
    tickets = relationship("Ticket", back_populates="seat")

    __table_args__ = (
        UniqueConstraint("airplane_id", "row_number", "seat_letter", name="uq_airplane_seat"),
    )

    def __repr__(self) -> str:
        return f"<Seat(airplane_id={self.airplane_id}, row={self.row_number}{self.seat_letter}, category='{self.category}')>"