from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from db.base import Base

class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    
    # Внешние ключи
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    flight_id = Column(Integer, ForeignKey("flights.id"), nullable=False)
    
    # Данные пассажира и места
    passenger_name = Column(String, nullable=False)
    passport_number = Column(String, nullable=True)
    nationality = Column(String, nullable=True)
    seat_number = Column(String, nullable=False)  # Например, "12A"
    ticket_number = Column(String, unique=True, nullable=False) # Уникальный номер билета

    # 🔗 Отношения
    flight = relationship("Flight", back_populates="tickets")
    booking = relationship("Booking", back_populates="tickets")