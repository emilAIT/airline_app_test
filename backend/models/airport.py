from sqlalchemy import Column, String
from sqlalchemy.orm import relationship

from db.base import Base

class Airport(Base):
    __tablename__ = "airports"

    code = Column(String(3), primary_key=True, index=True)  # IST, LHR
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    country = Column(String, nullable=False)

    departures = relationship(
        "Flight",
        foreign_keys="Flight.origin_code",
        back_populates="origin"
    )

    arrivals = relationship(
        "Flight",
        foreign_keys="Flight.destination_code",
        back_populates="destination"
    )