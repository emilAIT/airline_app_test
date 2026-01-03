"""
Staff API routes - flight and airplane management (STAFF only).
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.core.dependencies import get_db, require_role
from app.models.user import User
from app.models.flight import Flight
from app.models.booking import Booking
from app.models.airplane import Airplane
from app.models.announcement import Announcement
from app.models.notification import Notification
from app.models.seat_template import SeatTemplate
from app.repositories.flight import flight_repository
from app.repositories.booking import booking_repository
from app.core.exceptions import NotFound, ValidationError


router = APIRouter()


# ==================== SCHEMAS ====================

class AirplaneCreate(BaseModel):
    """Schema for creating an airplane."""
    registration_number: str = Field(..., max_length=20, description="Unique registration number (e.g., UP-B7701)")
    model: str = Field(..., max_length=100, description="Aircraft model (e.g., Boeing 737-800)")
    manufacturer: Optional[str] = Field(None, max_length=100, description="Manufacturer (e.g., Boeing)")
    total_seats: int = Field(..., gt=0, description="Total seating capacity")


class AirplaneCreateWithSeats(BaseModel):
    """Schema for creating an airplane with auto-generated seat templates."""
    name: str = Field(..., max_length=100, description="Aircraft name/registration")
    model_type: str = Field(..., max_length=100, description="Aircraft model")
    total_rows: int = Field(..., gt=0, le=100, description="Total number of rows")
    seats_per_row: int = Field(..., gt=0, le=10, description="Seats per row (e.g., 6 for A-F)")
    extra_legroom_rows_count: int = Field(0, ge=0, description="Number of extra legroom rows from row 1")
    
    @property
    def total_seats(self) -> int:
        return self.total_rows * self.seats_per_row


class FlightResponse(BaseModel):
    """Flight details for staff management."""
    id: int
    flight_number: str
    origin_code: str
    origin_city: str
    destination_code: str
    destination_city: str
    airplane_name: Optional[str] = None
    airplane_model: Optional[str] = None
    departure_time: str
    arrival_time: str
    price: float
    status: str
    terminal: Optional[str] = None
    gate: Optional[str] = None


class FlightUpdateStatus(BaseModel):
    """Schema for updating flight status."""
    status: str = Field(..., description="Flight status: SCHEDULED, BOARDING, DELAYED, CANCELLED, DEPARTED, LANDED")
    departure_time: Optional[str] = Field(None, description="New departure time for DELAYED flights (ISO format)")


class AirplaneUpdate(BaseModel):
    """Schema for updating an airplane."""
    model: Optional[str] = Field(None, max_length=100)
    manufacturer: Optional[str] = Field(None, max_length=100)
    total_seats: Optional[int] = Field(None, gt=0)


class AirplaneResponse(BaseModel):
    """Airplane response schema."""
    id: int
    registration_number: str
    model: str
    manufacturer: Optional[str]
    total_seats: int
    created_at: str
    
    class Config:
        from_attributes = True


class FlightCreate(BaseModel):
    """Schema for creating a flight."""
    flight_number: str = Field(..., max_length=10, description="Flight number (e.g., KC101)")
    airplane_id: int = Field(..., description="ID of assigned airplane")
    origin_airport_id: int = Field(..., description="Origin airport ID")
    destination_airport_id: int = Field(..., description="Destination airport ID")
    departure_time: datetime = Field(..., description="Departure time (ISO 8601)")
    arrival_time: datetime = Field(..., description="Arrival time (ISO 8601)")
    base_price: float = Field(..., ge=0, description="Base economy price")
    terminal: Optional[str] = Field(None, max_length=10, description="Terminal (e.g., A)")
    gate: Optional[str] = Field(None, max_length=10, description="Gate (e.g., 12)")
    status: str = Field(default="SCHEDULED", description="Flight status")


class FlightUpdate(BaseModel):
    """Schema for updating a flight."""
    departure_time: Optional[datetime] = None
    arrival_time: Optional[datetime] = None
    base_price: Optional[float] = Field(None, ge=0)
    status: Optional[str] = None


class AnnouncementCreate(BaseModel):
    """Schema for creating an announcement."""
    flight_id: Optional[int] = Field(None, description="Flight ID (None for general announcements)")
    message: str = Field(..., min_length=1, max_length=500, description="Announcement message")
    announcement_type: str = Field(default="INFO", description="Type: INFO, DELAY, GATE_CHANGE, CANCELLATION")


class AnnouncementUpdate(BaseModel):
    """Schema for updating an announcement."""
    message: Optional[str] = Field(None, min_length=1, max_length=500)
    announcement_type: Optional[str] = None


class AnnouncementResponse(BaseModel):
    """Announcement response schema."""
    id: int
    flight_id: int
    message: str
    announcement_type: str
    created_at: str
    
    class Config:
        from_attributes = True


class StaffBookingResponse(BaseModel):
    """Booking response schema for staff management."""
    id: int
    pnr: str
    user_id: int
    flight_id: int
    total_amount: float
    status: str
    created_at: str
    seats_held_until: Optional[str] = None


class StaffBookingUpdate(BaseModel):
    """Schema for updating a booking (staff)."""
    status: Optional[str] = None


# ==================== AIRPLANES CRUD ====================

@router.post("/airplanes", response_model=AirplaneResponse, status_code=201)
def create_airplane_with_seats(
    data: AirplaneCreateWithSeats,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Create a new airplane with auto-generated seat templates.
    
    **STAFF ONLY**
    
    Generates seat templates automatically:
    - Rows 1 to extra_legroom_rows_count: category='extra_legroom'
    - Remaining rows: category='standard'
    - Seat letters: A, B, C, D, E, F, ... (based on seats_per_row)
    
    **Validation:**
    - total_rows must be >= extra_legroom_rows_count
    """
    # Validation
    if data.extra_legroom_rows_count > data.total_rows:
        raise ValidationError(
            f"extra_legroom_rows_count ({data.extra_legroom_rows_count}) "
            f"cannot exceed total_rows ({data.total_rows})"
        )
    
    # Check if registration number already exists
    existing = db.query(Airplane).filter(
        Airplane.registration_number == data.name
    ).first()
    
    if existing:
        raise ValidationError("Airplane with this registration number already exists")
    
    # Create airplane
    airplane = Airplane(
        registration_number=data.name,
        model=data.model_type,
        manufacturer=None,
        total_seats=data.total_seats
    )
    
    db.add(airplane)
    db.flush()  # Get airplane.id without committing
    
    # Generate seat letters (A, B, C, D, E, F, ...)
    seat_letters = [chr(65 + i) for i in range(data.seats_per_row)]  # A=65 in ASCII
    
    # Generate seat templates
    seat_templates = []
    for row in range(1, data.total_rows + 1):
        # Determine category
        if row <= data.extra_legroom_rows_count:
            category = "extra_legroom"
        else:
            category = "standard"
        
        # Create seats for this row
        for letter in seat_letters:
            seat_number = f"{row}{letter}"
            seat_template = SeatTemplate(
                airplane_id=airplane.id,
                seat_number=seat_number,
                seat_class=category.upper(),  # Store as EXTRA_LEGROOM or STANDARD
                is_available=True
            )
            seat_templates.append(seat_template)
    
    db.bulk_save_objects(seat_templates)
    db.commit()
    db.refresh(airplane)
    
    return AirplaneResponse(
        id=airplane.id,
        registration_number=airplane.registration_number,
        model=airplane.model,
        manufacturer=airplane.manufacturer,
        total_seats=airplane.total_seats,
        created_at=airplane.created_at.isoformat()
    )


@router.post("/airplanes/simple", response_model=AirplaneResponse, status_code=201)
def create_airplane_simple(
    data: AirplaneCreate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Create a new airplane (without seat templates).
    
    **STAFF ONLY**
    
    Creates an airplane in the fleet. Seat map will be generated dynamically
    based on total_seats when flights are queried.
    """
    # Check if registration number already exists
    existing = db.query(Airplane).filter(
        Airplane.registration_number == data.registration_number
    ).first()
    
    if existing:
        raise ValidationError("Airplane with this registration number already exists")
    
    airplane = Airplane(
        registration_number=data.registration_number,
        model=data.model,
        manufacturer=data.manufacturer,
        total_seats=data.total_seats
    )
    
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    
    return AirplaneResponse(
        id=airplane.id,
        registration_number=airplane.registration_number,
        model=airplane.model,
        manufacturer=airplane.manufacturer,
        total_seats=airplane.total_seats,
        created_at=airplane.created_at.isoformat()
    )


@router.get("/airplanes", response_model=List[AirplaneResponse])
def list_airplanes(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    List all airplanes.
    
    **STAFF ONLY**
    """
    airplanes = db.query(Airplane).offset(skip).limit(limit).all()
    
    return [
        AirplaneResponse(
            id=ap.id,
            registration_number=ap.registration_number,
            model=ap.model,
            manufacturer=ap.manufacturer,
            total_seats=ap.total_seats,
            created_at=ap.created_at.isoformat()
        )
        for ap in airplanes
    ]


@router.get("/airplanes/{airplane_id}", response_model=AirplaneResponse)
def get_airplane(
    airplane_id: int,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Get airplane by ID.
    
    **STAFF ONLY**
    """
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise NotFound("Airplane")
    
    return AirplaneResponse(
        id=airplane.id,
        registration_number=airplane.registration_number,
        model=airplane.model,
        manufacturer=airplane.manufacturer,
        total_seats=airplane.total_seats,
        created_at=airplane.created_at.isoformat()
    )


@router.patch("/airplanes/{airplane_id}", response_model=AirplaneResponse)
def update_airplane(
    airplane_id: int,
    data: AirplaneUpdate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Update airplane details.
    
    **STAFF ONLY**
    
    Note: Changing total_seats will affect future seat map generation.
    """
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise NotFound("Airplane")
    
    if data.model is not None:
        airplane.model = data.model
    if data.manufacturer is not None:
        airplane.manufacturer = data.manufacturer
    if data.total_seats is not None:
        airplane.total_seats = data.total_seats
    
    db.commit()
    db.refresh(airplane)
    
    return AirplaneResponse(
        id=airplane.id,
        registration_number=airplane.registration_number,
        model=airplane.model,
        manufacturer=airplane.manufacturer,
        total_seats=airplane.total_seats,
        created_at=airplane.created_at.isoformat()
    )


@router.delete("/airplanes/{airplane_id}", status_code=204)
def delete_airplane(
    airplane_id: int,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Delete an airplane.
    
    **STAFF ONLY**
    
    Warning: Cannot delete airplane if it has scheduled flights.
    """
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise NotFound("Airplane")
    
    # Check if airplane has flights
    has_flights = db.query(Flight).filter(Flight.airplane_id == airplane_id).first()
    if has_flights:
        raise ValidationError("Cannot delete airplane with existing flights")
    
    db.delete(airplane)
    db.commit()
    
    return None


# ==================== FLIGHTS CRUD ====================

@router.post("/flights", response_model=FlightResponse, status_code=201)
def create_flight(
    data: FlightCreate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Create a new flight.
    
    **STAFF ONLY**
    
    Validations:
        - Flight number must be unique
        - Airplane must exist
        - Origin and destination airports must exist and be different
        - Arrival time must be after departure time
    """
    # Validate flight number
    existing = db.query(Flight).filter(Flight.flight_number == data.flight_number).first()
    if existing:
        raise ValidationError("Flight number already exists")
    
    # Validate airplane exists
    airplane = db.query(Airplane).filter(Airplane.id == data.airplane_id).first()
    if not airplane:
        raise NotFound("Airplane")
    
    # Validate airports exist
    from app.models.airport import Airport
    origin = db.query(Airport).filter(Airport.id == data.origin_airport_id).first()
    destination = db.query(Airport).filter(Airport.id == data.destination_airport_id).first()
    
    if not origin or not destination:
        raise NotFound("Airport")
    
    if data.origin_airport_id == data.destination_airport_id:
        raise ValidationError("Origin and destination must be different")
    
    # Validate times
    if data.arrival_time <= data.departure_time:
        raise ValidationError("Arrival time must be after departure time")
    
    # Validate status
    valid_statuses = ["SCHEDULED", "BOARDING", "DELAYED", "CANCELLED", "DEPARTED", "LANDED"]
    if data.status not in valid_statuses:
        raise ValidationError(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")
    
    flight = Flight(
        flight_number=data.flight_number,
        airplane_id=data.airplane_id,
        origin_id=data.origin_airport_id,  # Model uses origin_id
        destination_id=data.destination_airport_id,  # Model uses destination_id
        departure_time=data.departure_time,
        arrival_time=data.arrival_time,
        price=data.base_price,  # Model uses price
        status=data.status,
        terminal=data.terminal,
        gate=data.gate
    )
    
    db.add(flight)
    db.commit()
    db.refresh(flight)
    
    # Fetch related data for response
    from app.models.airport import Airport
    origin = db.query(Airport).filter(Airport.id == flight.origin_id).first()
    destination = db.query(Airport).filter(Airport.id == flight.destination_id).first()
    airplane = db.query(Airplane).filter(Airplane.id == flight.airplane_id).first()
    
    return FlightResponse(
        id=flight.id,
        flight_number=flight.flight_number,
        origin_code=origin.code,
        origin_city=origin.city,
        destination_code=destination.code,
        destination_city=destination.city,
        airplane_name=airplane.registration_number if airplane else None,
        airplane_model=airplane.model if airplane else None,
        departure_time=flight.departure_time.isoformat(),
        arrival_time=flight.arrival_time.isoformat(),
        price=float(flight.price),
        status=flight.status,
        terminal=flight.terminal,
        gate=flight.gate
    )





@router.patch("/flights/{flight_id}", response_model=FlightResponse)
def update_flight(
    flight_id: int,
    data: FlightUpdate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Update flight details.
    
    **STAFF ONLY**
    
    Common use cases:
        - Change status (DELAYED, CANCELLED, BOARDING, etc.)
        - Update departure/arrival times
        - Adjust base price
    """
    flight = flight_repository.get_by_id(db, flight_id)
    if not flight:
        raise NotFound("Flight")
    
    if data.departure_time is not None:
        flight.departure_time = data.departure_time
    
    if data.arrival_time is not None:
        flight.arrival_time = data.arrival_time
    
    # Validate times after update
    if flight.arrival_time <= flight.departure_time:
        raise ValidationError("Arrival time must be after departure time")
    
    if data.base_price is not None:
        flight.base_price = data.base_price
    
    if data.status is not None:
        valid_statuses = ["SCHEDULED", "BOARDING", "DELAYED", "CANCELLED", "DEPARTED", "LANDED"]
        if data.status not in valid_statuses:
            raise ValidationError(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")
        flight.status = data.status
    
    db.commit()
    db.refresh(flight)
    
    return FlightResponse(
        id=flight.id,
        flight_number=flight.flight_number,
        airplane_id=flight.airplane_id,
        origin_airport_id=flight.origin_airport_id,
        destination_airport_id=flight.destination_airport_id,
        departure_time=flight.departure_time.isoformat(),
        arrival_time=flight.arrival_time.isoformat(),
        base_price=float(flight.base_price),
        status=flight.status,
        created_at=flight.created_at.isoformat()
    )


# ==================== ANNOUNCEMENTS ====================

@router.post("/announcements", response_model=AnnouncementResponse, status_code=201)
def create_announcement(
    data: AnnouncementCreate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Publish flight announcement.
    
    **STAFF ONLY**
    
    Types:
        - INFO: General information
        - DELAY: Flight delayed
        - GATE_CHANGE: Gate changed
        - CANCELLATION: Flight cancelled
    
    Automatically creates notifications for all passengers with confirmed bookings on this flight.
    """
    # Validate flight exists
    flight = flight_repository.get_by_id(db, data.flight_id)
    if not flight:
        raise NotFound("Flight")
    
    valid_types = ["INFO", "DELAY", "GATE_CHANGE", "CANCELLATION"]
    if data.announcement_type not in valid_types:
        raise ValidationError(f"Invalid type. Must be one of: {', '.join(valid_types)}")
    
    # Generate title based on announcement type
    type_titles = {
        "INFO": f"Flight {flight.flight_number}: Information",
        "DELAY": f"Flight {flight.flight_number}: Delayed",
        "GATE_CHANGE": f"Flight {flight.flight_number}: Gate Change",
        "CANCELLATION": f"Flight {flight.flight_number}: Cancelled"
    }
    
    announcement = Announcement(
        flight_id=data.flight_id,
        created_by=current_user.id,
        title=type_titles[data.announcement_type],
        message=data.message,
        announcement_type=data.announcement_type
    )
    
    db.add(announcement)
    db.flush()  # Get announcement.id without committing
    
    # Find all passengers with confirmed bookings on this flight
    confirmed_bookings = db.query(Booking).filter(
        Booking.flight_id == data.flight_id,
        Booking.status == "CONFIRMED"
    ).all()
    
    # Create notification for each passenger
    for booking in confirmed_bookings:
        notification = Notification(
            user_id=booking.user_id,
            flight_id=data.flight_id,
            announcement_id=announcement.id,
            title=type_titles[data.announcement_type],
            message=data.message,
            notification_type=data.announcement_type,
            is_read=False
        )
        db.add(notification)
    
    db.commit()
    db.refresh(announcement)
    
    return AnnouncementResponse(
        id=announcement.id,
        flight_id=announcement.flight_id,
        message=announcement.message,
        announcement_type=announcement.announcement_type,
        created_at=announcement.created_at.isoformat()
    )


@router.get("/announcements/flight/{flight_id}", response_model=List[AnnouncementResponse])
def get_flight_announcements(
    flight_id: int,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Get all announcements for a flight.
    
    **STAFF ONLY**
    """
    announcements = db.query(Announcement).filter(
        Announcement.flight_id == flight_id
    ).order_by(Announcement.created_at.desc()).all()
    
    return [
        AnnouncementResponse(
            id=a.id,
            flight_id=a.flight_id,
            message=a.message,
            announcement_type=a.announcement_type,
            created_at=a.created_at.isoformat()
        )
        for a in announcements
    ]


@router.patch("/announcements/{announcement_id}", response_model=AnnouncementResponse)
def update_announcement(
    announcement_id: int,
    data: AnnouncementUpdate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """Update an existing announcement.

    **STAFF ONLY**
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise NotFound("Announcement")

    if data.message is not None:
        announcement.message = data.message

    if data.announcement_type is not None:
        valid_types = ["INFO", "DELAY", "GATE_CHANGE", "CANCELLATION"]
        if data.announcement_type not in valid_types:
            raise ValidationError(f"Invalid type. Must be one of: {', '.join(valid_types)}")
        announcement.announcement_type = data.announcement_type

    db.commit()
    db.refresh(announcement)

    return AnnouncementResponse(
        id=announcement.id,
        flight_id=announcement.flight_id,
        message=announcement.message,
        announcement_type=announcement.announcement_type,
        created_at=announcement.created_at.isoformat(),
    )


@router.delete("/announcements/{announcement_id}", status_code=204)
def delete_announcement(
    announcement_id: int,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """Delete an announcement.

    **STAFF ONLY**
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise NotFound("Announcement")

    db.delete(announcement)
    db.commit()
    return None


# ==================== BOOKINGS (STAFF) ====================

@router.get("/bookings", response_model=List[StaffBookingResponse])
def list_bookings(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    status: Optional[str] = Query(None, description="Filter by status"),
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db),
):
    """List all bookings (staff view).

    **STAFF ONLY**
    """
    query = db.query(Booking)
    if status:
        query = query.filter(Booking.status == status)

    bookings = query.order_by(Booking.created_at.desc()).offset(skip).limit(limit).all()
    result: List[StaffBookingResponse] = []

    for b in bookings:
        seats_held_until = None
        holds = getattr(b, "seat_holds", None) or []
        if b.status == "CREATED" and holds:
            seats_held_until = max(h.held_until for h in holds).isoformat()

        result.append(
            StaffBookingResponse(
                id=b.id,
                pnr=b.pnr,
                user_id=b.user_id,
                flight_id=b.flight_id,
                total_amount=float(b.total_amount),
                status=b.status,
                created_at=b.created_at.isoformat(),
                seats_held_until=seats_held_until,
            )
        )

    return result


# ==================== FLIGHT MANAGEMENT ====================

@router.get("/flights", response_model=List[FlightResponse])
def list_flights(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    List all flights with airport details (JOIN).
    
    **STAFF ONLY**
    """
    flights = db.query(Flight).offset(skip).limit(limit).all()
    
    return [
        FlightResponse(
            id=f.id,
            flight_number=f.flight_number,
            origin_code=f.origin.code,
            origin_city=f.origin.city,
            destination_code=f.destination.code,
            destination_city=f.destination.city,
            airplane_name=f.airplane.registration_number if f.airplane else None,
            airplane_model=f.airplane.model if f.airplane else None,
            departure_time=f.departure_time.isoformat(),
            arrival_time=f.arrival_time.isoformat(),
            price=float(f.price),
            status=f.status,
            terminal=f.terminal,
            gate=f.gate
        )
        for f in flights
    ]


@router.post("/flights", response_model=FlightResponse)
def create_flight(
    data: FlightCreate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Create a new flight.
    
    Validations:
    - Origin and destination must be different
    - Airplane must exist (if provided)
    - Flight number must be unique
    
    **STAFF ONLY**
    """
    from app.models.airport import Airport
    
    # Validate origin != destination
    if data.origin_airport_id == data.destination_airport_id:
        raise ValidationError("Origin and destination airports must be different")
    
    # Check if flight number already exists
    existing = db.query(Flight).filter(Flight.flight_number == data.flight_number).first()
    if existing:
        raise ValidationError(f"Flight number {data.flight_number} already exists")
    
    # Validate airports exist
    origin = db.query(Airport).filter(Airport.id == data.origin_airport_id).first()
    if not origin:
        raise NotFound(f"Origin airport with ID {data.origin_airport_id}")
    
    destination = db.query(Airport).filter(Airport.id == data.destination_airport_id).first()
    if not destination:
        raise NotFound(f"Destination airport with ID {data.destination_airport_id}")
    
    # Validate airplane exists (if provided)
    airplane = None
    if data.airplane_id:
        airplane = db.query(Airplane).filter(Airplane.id == data.airplane_id).first()
        if not airplane:
            raise NotFound(f"Airplane with ID {data.airplane_id}")
    
    # Create flight
    flight = Flight(
        flight_number=data.flight_number,
        origin_id=data.origin_airport_id,
        destination_id=data.destination_airport_id,
        airplane_id=data.airplane_id,
        departure_time=data.departure_time,
        arrival_time=data.arrival_time,
        price=data.base_price,
        status=data.status,
        terminal=data.terminal,
        gate=data.gate
    )
    
    db.add(flight)
    db.commit()
    db.refresh(flight)
    
    return FlightResponse(
        id=flight.id,
        flight_number=flight.flight_number,
        origin_code=origin.code,
        origin_city=origin.city,
        destination_code=destination.code,
        destination_city=destination.city,
        airplane_name=airplane.registration_number if airplane else None,
        airplane_model=airplane.model if airplane else None,
        departure_time=flight.departure_time.isoformat(),
        arrival_time=flight.arrival_time.isoformat(),
        price=float(flight.price),
        status=flight.status,
        terminal=flight.terminal,
        gate=flight.gate
    )


@router.patch("/flights/{flight_id}", response_model=FlightResponse)
def update_flight_status(
    flight_id: int,
    data: FlightUpdateStatus,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """
    Update flight status and handle business logic.
    
    Business rules:
    - If status changes to DELAYED, departure_time must be provided
    - If status changes to CANCELLED, all related bookings are auto-cancelled
    
    **STAFF ONLY**
    """
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise NotFound("Flight")
    
    # Validate status
    valid_statuses = ["SCHEDULED", "BOARDING", "DELAYED", "CANCELLED", "DEPARTED", "LANDED"]
    if data.status not in valid_statuses:
        raise ValidationError(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")
    
    # Update status
    flight.status = data.status
    
    # Handle DELAYED: require new departure_time
    if data.status == "DELAYED":
        if not data.departure_time:
            raise ValidationError("departure_time is required when status is DELAYED")
        try:
            flight.departure_time = datetime.fromisoformat(data.departure_time)
        except ValueError:
            raise ValidationError("Invalid departure_time format. Use ISO format (e.g., 2026-01-05T10:30:00)")
    
    # Handle CANCELLED: cancel all related bookings
    if data.status == "CANCELLED":
        bookings = db.query(Booking).filter(
            Booking.flight_id == flight_id,
            Booking.status.in_(["CREATED", "CONFIRMED"])
        ).all()
        
        for booking in bookings:
            booking.status = "CANCELLED"
        
        db.add_all(bookings)
    
    db.commit()
    db.refresh(flight)
    
    return FlightResponse(
        id=flight.id,
        flight_number=flight.flight_number,
        origin_code=flight.origin.code,
        origin_city=flight.origin.city,
        destination_code=flight.destination.code,
        destination_city=flight.destination.city,
        airplane_name=flight.airplane.registration_number if flight.airplane else None,
        airplane_model=flight.airplane.model if flight.airplane else None,
        departure_time=flight.departure_time.isoformat(),
        arrival_time=flight.arrival_time.isoformat(),
        price=float(flight.price),
        status=flight.status,
        terminal=flight.terminal,
        gate=flight.gate
    )


@router.patch("/bookings/{booking_id}", response_model=StaffBookingResponse)
def update_booking(
    booking_id: int,
    data: StaffBookingUpdate,
    current_user: User = Depends(require_role("STAFF")),
    db: Session = Depends(get_db),
):
    """Update booking status.

    **STAFF ONLY**
    """
    booking = booking_repository.get_by_id(db, booking_id)
    if not booking:
        raise NotFound("Booking")

    if data.status is not None:
        valid = ["CREATED", "CONFIRMED", "CANCELLED", "CHECKED_IN"]
        if data.status not in valid:
            raise ValidationError(f"Invalid status. Must be one of: {', '.join(valid)}")
        booking.status = data.status

    db.commit()
    db.refresh(booking)

    seats_held_until = None
    holds = getattr(booking, "seat_holds", None) or []
    if booking.status == "CREATED" and holds:
        seats_held_until = max(h.held_until for h in holds).isoformat()

    return StaffBookingResponse(
        id=booking.id,
        pnr=booking.pnr,
        user_id=booking.user_id,
        flight_id=booking.flight_id,
        total_amount=float(booking.total_amount),
        status=booking.status,
        created_at=booking.created_at.isoformat(),
        seats_held_until=seats_held_until,
    )
