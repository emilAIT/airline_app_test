from sqlalchemy import Column, Integer, String, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base


class Airplane(Base):
    __tablename__ = "airplanes"

    id = Column(Integer, primary_key=True, index=True)
    model = Column(String, nullable=False)
    registration_number = Column(String, unique=True, nullable=False)
    seat_template = Column(JSON, nullable=False)  # e.g., {"rows": 30, "seats_per_row": 6, "layout": "3-3"}
    total_seats = Column(Integer, nullable=False)
    
    # Relationships
    flights = relationship("Flight", back_populates="airplane")

