from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from db.base import Base

class Airplane(Base):
    __tablename__ = "airplanes"

    id = Column(Integer, primary_key=True, index=True)
    model = Column(String, nullable=False, unique=True)
    

    seat_map_templates = relationship(
        "SeatMapTemplates",
        back_populates="airplane",
        cascade="all, delete-orphan"
    )

    flights = relationship(
        "Flight",
        back_populates="airplane"
    )
