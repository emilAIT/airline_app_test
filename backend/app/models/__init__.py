"""Models package.

This project originally included many models (auth/bookings/etc).

The exam-aligned backend only *needs* Airport/Flight/Seat, but the Flutter
client in this workspace also expects auth/profile flows.

So we register the minimal exam tables plus the minimal auth/profile tables.
"""

from app.models.airport import Airport
from app.models.airplane import Airplane
from app.models.announcement import Announcement
from app.models.booking import Booking
from app.models.booking_passenger import BookingPassenger
from app.models.checkin import CheckIn
from app.models.flight import Flight
from app.models.notification import Notification
from app.models.passenger_profile import PassengerProfile
from app.models.payment import Payment
from app.models.seat import Seat
from app.models.seat_hold import SeatHold
from app.models.seat_template import SeatTemplate
from app.models.ticket import Ticket
from app.models.user import User

__all__ = [
	"Airplane",
	"Airport",
	"Announcement",
	"Flight",
	"Seat",
	"SeatTemplate",
	"User",
	"PassengerProfile",
	"Booking",
	"BookingPassenger",
	"SeatHold",
	"Ticket",
	"Payment",
	"CheckIn",
	"Notification",
]
