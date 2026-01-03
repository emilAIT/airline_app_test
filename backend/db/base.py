from sqlalchemy.orm import declarative_base

Base = declarative_base()

from models.user import User
from models.passenger_profile import PassengerProfile
from models.flight import Flight
from models.airplane import Airplane
from models.airport import Airport
from models.seat import SeatMapTemplates
from models.ticket import Ticket
from models.booking import Booking
from models.payment import Payment
from models.checkin import CheckIn
from models.announcement import Announcement
from models.seat_hold import SeatHold