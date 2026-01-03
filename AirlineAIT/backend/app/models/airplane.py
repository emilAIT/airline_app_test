"""
Airplane and SeatTemplate models.

Airplane: Aircraft with registration, model, and status (ACTIVE, MAINTENANCE, RETIRED).
SeatTemplate: Reusable seat layout configurations (rows, categories, aisle positions).

Part of: Backend Models
"""
import enum
from sqlalchemy import Column, Integer, String, ForeignKey, JSON, Enum
from sqlalchemy.orm import relationship
from app.db.base import Base


class AirplaneStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    MAINTENANCE = "MAINTENANCE"
    RETIRED = "RETIRED"


class Airplane(Base):
    __tablename__ = "airplanes"

    id = Column(Integer, primary_key=True, index=True)
    model = Column(String, nullable=False)
    registration_number = Column(String, unique=True, nullable=False)
    seat_template_id = Column(Integer, ForeignKey("seat_templates.id"), nullable=False)
    status = Column(Enum(AirplaneStatus), default=AirplaneStatus.ACTIVE, nullable=False)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    # Relationships
    seat_template = relationship("SeatTemplate", back_populates="airplanes")
    flights = relationship("Flight", back_populates="airplane")
    creator = relationship("User", foreign_keys=[created_by])


class SeatTemplate(Base):
    __tablename__ = "seat_templates"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    rows = Column(Integer, nullable=False)
    seats_per_row = Column(Integer, nullable=False)
    seat_labels = Column(JSON, nullable=False)  # e.g., ["A", "B", "C", "D", "E", "F"]
    seat_categories = Column(JSON, nullable=False)  # e.g., {"1-5": "EXTRA_LEGROOM", "6-30": "STANDARD"}
    class_layouts = Column(JSON, nullable=True)  # e.g., {"BUSINESS": {"rows": 2, "seats_per_row": 4}}
    aisle_positions = Column(JSON, default=[])  # e.g., [3] -> aisle after column 3
    emergency_exits = Column(JSON, default=[])  # e.g., [12, 13] -> exit at rows 12 and 13
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    # Relationships
    airplanes = relationship("Airplane", back_populates="seat_template")
    creator = relationship("User", foreign_keys=[created_by])

