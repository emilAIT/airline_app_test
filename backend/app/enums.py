from enum import Enum


class UserRole(str, Enum):
    PASSENGER = "PASSENGER"
    STAFF = "STAFF"


class BookingStatus(str, Enum):
    CREATED = "CREATED"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class FlightStatus(str, Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"
    DEPARTED = "DEPARTED"
    LANDED = "LANDED"


class PaymentStatus(str, Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"


class PaymentMethod(str, Enum):
    CARD = "CARD"
    APPLE_PAY = "APPLE_PAY"
    GOOGLE_PAY = "GOOGLE_PAY"


class SeatCategory(str, Enum):
    STANDARD = "STANDARD"
    EXTRA_LEGROOM = "EXTRA_LEGROOM"


class AnnouncementType(str, Enum):
    DELAY = "DELAY"
    CANCELLATION = "CANCELLATION"
    GATE_CHANGE = "GATE_CHANGE"
    BOARDING_STARTED = "BOARDING_STARTED"
    GENERAL = "GENERAL"

