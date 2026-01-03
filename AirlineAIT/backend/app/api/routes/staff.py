"""
Staff Management API routes.

Comprehensive endpoints for staff and admin operations:
- Airplane management (create, update, delete)
- Seat template management
- Flight management (create, update, delete, status)
- Announcement management
- Booking management
- Airport management
- User role management

Includes auto-status updates for flights based on time.

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status, Body
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.session import get_db
from app.api.deps import get_current_staff
from app.models.user import User, UserRole
from app.schemas.airplane import (
    SeatTemplateCreate, SeatTemplateResponse, AirplaneCreate, AirplaneResponse, AirplaneUpdate
)
from app.schemas.flight import FlightCreate, FlightUpdate, FlightResponse
from app.schemas.announcement import AnnouncementCreate, AnnouncementResponse
from app.schemas.airport import AirportCreate, AirportUpdate, AirportResponse
from app.schemas.booking import BookingResponse, BookingDetailResponse
from app.schemas.payment import PaymentDetailResponse
from app.schemas.auth import UserResponse
from app.models.airplane import SeatTemplate, Airplane, AirplaneStatus
from app.models.flight import Flight, FlightStatus
from app.models.announcement import Announcement
from app.models.airport import Airport
from app.models.booking import Booking
from app.services.seat_hold import generate_seat_map
from app.utils.authorization import (
    require_airplane_access, require_flight_access, require_booking_access,
    require_announcement_access, log_critical_action
)
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

router = APIRouter(prefix="/staff", tags=["Staff"])


# Staff Assignment Management
@router.get("/users", response_model=List[UserResponse])
def list_users(
    role: Optional[str] = None,
    is_approved: Optional[bool] = None,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List users (Admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can view all users"
        )
    
    query = db.query(User)
    if role:
        role_enum = UserRole[role.upper()] if role.upper() in [r.name for r in UserRole] else None
        if role_enum:
            query = query.filter(User.role == role_enum)
            
    if is_approved is not None:
        query = query.filter(User.is_approved == is_approved)
    
    users = query.all()
    return users


class PromoteToStaffRequest(BaseModel):
    # No fields needed for now
    pass


@router.post("/users/{user_id}/promote-to-staff")
def promote_user_to_staff(
    user_id: int,
    # request: PromoteToStaffRequest = Body(...), # No body needed
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Promote a user to staff (Admin only)"""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can promote users to staff"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot change admin role"
        )
    
    
    # airplane = db.query(Airplane).filter(Airplane.id == request.airplane_id).first()
    # if not airplane: ...
    # No airplane assignment
    
    was_staff = user.role == UserRole.STAFF
    user.role = UserRole.STAFF
    # user.assigned_airplane_id = request.airplane_id # Removed
    db.commit()
    db.refresh(user)
    
    action = "PROMOTE_TO_STAFF"
    log_critical_action(
        current_user, action, "User", user_id,
        f"User: {user.email}, Role: {user.role.value}"
    )
    
    return {
        "message": f"User {user.email} promoted to staff",
        "user_id": user.id
    }





# Airplane & Seat Template Management
@router.post("/seat-templates", response_model=SeatTemplateResponse, status_code=status.HTTP_201_CREATED)
def create_seat_template(
    template_data: SeatTemplateCreate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a seat template (Admin/Staff)"""
    # Allow both admin and staff to create templates
    template = SeatTemplate(
        **template_data.dict(),
        created_by=current_user.id
    )
    db.add(template)
    db.commit()
    db.refresh(template)
    
    log_critical_action(current_user, "CREATE_SEAT_TEMPLATE", "SeatTemplate", template.id, f"Name: {template.name}")
    
    return template


@router.get("/seat-templates", response_model=List[SeatTemplateResponse])
def list_seat_templates(
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List seat templates (Admin/Staff: all)"""
    # Staff have global access now
    templates = db.query(SeatTemplate).all()
    return templates


@router.get("/seat-templates/{template_id}/preview")
def preview_seat_map(
    template_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Preview generated seat map for a template"""
    template = db.query(SeatTemplate).filter(SeatTemplate.id == template_id).first()
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Template not found"
        )
    
    seat_map = generate_seat_map(template)
    return {
        "template_id": template_id,
        "seat_map": seat_map,
        "total_seats": len(seat_map)
    }


@router.post("/airplanes", response_model=AirplaneResponse, status_code=status.HTTP_201_CREATED)
def create_airplane(
    airplane_data: AirplaneCreate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create an airplane (Admin or Staff - Staff can create without admin approval)"""
    # Verify template exists
    template = db.query(SeatTemplate).filter(SeatTemplate.id == airplane_data.seat_template_id).first()
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Seat template not found"
        )
    
    # Both Admin and approved Staff can create airplanes
    airplane = Airplane(
        **airplane_data.dict(),
        created_by=current_user.id
    )
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    
    log_critical_action(current_user, "CREATE_AIRPLANE", "Airplane", airplane.id, f"Model: {airplane.model}")
    
    return airplane


@router.get("/airplanes", response_model=List[AirplaneResponse])
def list_airplanes(
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List airplanes (Admin/Staff: all)"""
    airplanes = db.query(Airplane).all()
    return airplanes


@router.put("/airplanes/{airplane_id}", response_model=AirplaneResponse)
def update_airplane(
    airplane_id: int,
    airplane_data: AirplaneUpdate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Update an airplane (Admin or Staff assigned to it)"""
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airplane not found"
        )
    
    # Check access: Admin and Staff have global access
    # if current_user.role != UserRole.ADMIN:
    #     if current_user.assigned_airplane_id != airplane_id: ...
    pass

    original_status = airplane.status
    update_data = airplane_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(airplane, field, value)
    
    db.commit()
    db.refresh(airplane)
    
    # If changed to MAINTENANCE, cancel all active flights
    if airplane.status == AirplaneStatus.MAINTENANCE and original_status != AirplaneStatus.MAINTENANCE:
        from app.models.announcement import Announcement, AnnouncementType
        from app.models.flight import Flight, FlightStatus
        affected_flights = db.query(Flight).filter(
            Flight.airplane_id == airplane_id,
            Flight.status.in_([FlightStatus.SCHEDULED, FlightStatus.DELAYED, FlightStatus.BOARDING])
        ).all()
        
        for f in affected_flights:
            f.status = FlightStatus.CANCELLED
            
            # Create announcement for passengers
            announcement = Announcement(
                flight_id=f.id,
                type=AnnouncementType.CANCELLATION,
                title=f"Flight Canceled - {f.flight_number}",
                message="Flight canceled due to maintenance/repair.",
                created_at=datetime.utcnow()
            )
            db.add(announcement)
            log_critical_action(
                current_user, "AUTO_CANCEL_MAINTENANCE", "Flight", f.id,
                f"Flight {f.flight_number} automatically canceled due to airplane maintenance status change"
            )
        
        db.commit()
        if affected_flights:
            # Auto-cancel bookings for these flights
            from app.models.booking import Booking, BookingStatus
            flight_ids = [f.id for f in affected_flights]
            
            active_bookings = db.query(Booking).filter(
                Booking.flight_id.in_(flight_ids),
                Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.HOLD])
            ).all()
            
            for b in active_bookings:
                b.status = BookingStatus.CANCELLED
            
            db.commit()
            db.refresh(airplane) # Refresh to ensure relations are clear if needed
    
    log_critical_action(current_user, "UPDATE_AIRPLANE", "Airplane", airplane.id, f"Model: {airplane.model}, Status: {airplane.status.value}")
    
    return airplane


@router.delete("/airplanes/{airplane_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_airplane(
    airplane_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete an airplane (Staff Global)"""
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airplane not found"
        )
    
    # Check if airplane is used by any flights (active/scheduled)
    active_flights = db.query(Flight).filter(
        Flight.airplane_id == airplane_id,
        Flight.status != FlightStatus.CANCELLED,
        Flight.status != FlightStatus.LANDED
    ).all()
    
    if active_flights:
        flight_numbers = [f.flight_number for f in active_flights[:5]]  # Show first 5
        total = len(active_flights)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete airplane with {total} active/scheduled flight(s): {', '.join(flight_numbers)}{'...' if total > 5 else ''}. Cancel or complete flights first."
        )
    
    db.delete(airplane)
    db.commit()
    
    log_critical_action(current_user, "DELETE_AIRPLANE", "Airplane", airplane_id, f"Model: {airplane.model}")
    
    return None


def update_flight_status_based_on_time(flight: Flight, db: Session) -> bool:
    """
    Automatically updates flight status based on current time.
    Creates announcements for passengers when status changes.
    Returns True if status changed.
    """
    from app.models.announcement import Announcement, AnnouncementType
    from app.models.airport import Airport
    
    # Skip if cancelled
    if flight.status == FlightStatus.CANCELLED:
        return False
        
    # Use Kyrgyz time consistent with check-in and DB storage
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None) # naive local
    changes_made = False
    
    # -----------------------------------------------------
    # 1. Independent Check: Automatic "Check-in Started" Announcement
    # -----------------------------------------------------
    # Check-in opens 24 hours before departure.
    checkin_start = flight.departure_time - timedelta(hours=24)
    
    # If we are past check-in start time (and not yet landed/departed ideally, but simpler: just start time reached)
    if now >= checkin_start and flight.status not in [FlightStatus.CANCELLED, FlightStatus.DEPARTED, FlightStatus.LANDED]:
        # Check if we already announced it
        existing_announcement = db.query(Announcement).filter(
            Announcement.flight_id == flight.id,
            Announcement.type == AnnouncementType.CHECKIN_OPEN
        ).first()
        
        if not existing_announcement:
            # Create announcement
            origin_name = flight.origin_airport.code if flight.origin_airport else "Origin"
            dest_name = flight.destination_airport.code if flight.destination_airport else "Destination"
            
            announcement = Announcement(
                flight_id=flight.id,
                type=AnnouncementType.CHECKIN_OPEN,
                title=f"🎫 Check-in Open - Flight {flight.flight_number}",
                message=f"Online check-in is now open for flight {flight.flight_number} to {dest_name}. "
                        f"Please check in via the app to get your boarding pass. Check-in closes 1 hour before departure.",
                created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
            )
            db.add(announcement)
            changes_made = True
            
    original_status = flight.status
    new_status = None
    
    # Logic:
    # Landed: Now >= Arrival
    # Departed: Departure <= Now < Arrival
    # Boarding: Departure - 60m <= Now < Departure
    # Scheduled/Delayed: Now < Departure - 60m
    
    if now >= flight.arrival_time:
        if flight.status != FlightStatus.LANDED:
            flight.status = FlightStatus.LANDED
            new_status = FlightStatus.LANDED
    elif flight.departure_time <= now < flight.arrival_time:
        if flight.status != FlightStatus.DEPARTED:
            flight.status = FlightStatus.DEPARTED
            new_status = FlightStatus.DEPARTED
    elif (flight.departure_time - timedelta(minutes=60)) <= now < flight.departure_time:
        if flight.status != FlightStatus.BOARDING:
            flight.status = FlightStatus.BOARDING
            new_status = FlightStatus.BOARDING
    else:
        # Flight is more than 60 minutes in the future
        # Revert to SCHEDULED if it was already in a later state (rescheduled)
        if flight.status in [FlightStatus.BOARDING, FlightStatus.DEPARTED, FlightStatus.LANDED]:
            flight.status = FlightStatus.SCHEDULED
            new_status = FlightStatus.SCHEDULED
    
    # Create announcement if status changed
    if new_status and flight.status != original_status:
        db.add(flight)
        
        # Get airport info for announcement message
        origin = db.query(Airport).filter(Airport.id == flight.origin_airport_id).first()
        destination = db.query(Airport).filter(Airport.id == flight.destination_airport_id).first()
        origin_code = origin.code if origin else "---"
        dest_code = destination.code if destination else "---"
        
        # Create appropriate announcement based on new status
        if new_status == FlightStatus.BOARDING:
            announcement = Announcement(
                flight_id=flight.id,
                type=AnnouncementType.BOARDING_STARTED,
                title=f"🛫 Boarding Started - Flight {flight.flight_number}",
                message=f"Boarding has now started for flight {flight.flight_number} from {origin_code} to {dest_code}. "
                        f"Please proceed to Gate {flight.gate or 'TBA'}, Terminal {flight.terminal or 'TBA'}. "
                        f"Departure is scheduled for {flight.departure_time.strftime('%H:%M')}.",
                created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
            )
            db.add(announcement)
            
        elif new_status == FlightStatus.DEPARTED:
            announcement = Announcement(
                flight_id=flight.id,
                type=AnnouncementType.GENERAL,
                title=f"✈️ Flight Departed - {flight.flight_number}",
                message=f"Flight {flight.flight_number} has departed from {origin_code} and is now en route to {dest_code}. "
                        f"Estimated arrival time: {flight.arrival_time.strftime('%H:%M')}. Have a safe flight!",
                created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
            )
            db.add(announcement)
            
        elif new_status == FlightStatus.LANDED:
            announcement = Announcement(
                flight_id=flight.id,
                type=AnnouncementType.GENERAL,
                title=f"🛬 Flight Landed - {flight.flight_number}",
                message=f"Flight {flight.flight_number} has safely landed at {dest_code}. "
                        f"Thank you for flying with us! Please collect your luggage from the designated baggage claim area.",
                created_at=datetime.now(kyrgyz_tz).replace(tzinfo=None)
            )
            db.add(announcement)
        
            db.add(announcement)
        
        changes_made = True
    
    return changes_made


# Flight Management
@router.post("/flights", response_model=FlightResponse, status_code=status.HTTP_201_CREATED)
def create_flight(
    flight_data: FlightCreate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a flight (Admin: any airplane, Staff: only assigned airplane)"""
    
    # Check if flight number already exists
    if db.query(Flight).filter(Flight.flight_number == flight_data.flight_number).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Flight number {flight_data.flight_number} already exists"
        )

    # Ensure datetimes are naive UTC for SQLite consistency (stripping tzinfo if present)
    from datetime import timezone
    if flight_data.departure_time.tzinfo is not None:
        flight_data.departure_time = flight_data.departure_time.astimezone(timezone.utc).replace(tzinfo=None)
    if flight_data.arrival_time.tzinfo is not None:
        flight_data.arrival_time = flight_data.arrival_time.astimezone(timezone.utc).replace(tzinfo=None)

    # Verify airports exist
    from app.models.airport import Airport
    origin = db.query(Airport).filter(Airport.id == flight_data.origin_airport_id).first()
    destination = db.query(Airport).filter(Airport.id == flight_data.destination_airport_id).first()
    
    if not origin or not destination:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airport not found"
        )
    
    # Verify airplane exists
    airplane = db.query(Airplane).filter(Airplane.id == flight_data.airplane_id).first()
    if not airplane:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airplane not found"
        )
    
    # Check if airplane is active
    if airplane.status != AirplaneStatus.ACTIVE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Airplane {airplane.model} is not active (Status: {airplane.status.value})"
        )

    # Check for overlapping flights for this airplane
    overlapping_flight = db.query(Flight).filter(
        Flight.airplane_id == flight_data.airplane_id,
        Flight.status != FlightStatus.CANCELLED,
        Flight.status != FlightStatus.LANDED,
        Flight.departure_time < flight_data.arrival_time,
        Flight.arrival_time > flight_data.departure_time
    ).first()
    
    if overlapping_flight:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Airplane is already assigned to flight {overlapping_flight.flight_number} during this time."
        )

    # Check access: Admin and Staff have global access
    # if current_user.role == UserRole.STAFF: ...
    pass
    
    import json
    data = flight_data.dict()
    if data.get('category_prices'):
        data['category_prices'] = json.dumps(data['category_prices'])
    if data.get('category_allocations'):
        data['category_allocations'] = json.dumps(data['category_allocations'])
        
    flight = Flight(
        **data,
        created_by=current_user.id
    )
    db.add(flight)
    db.commit()
    db.refresh(flight)
    
    log_critical_action(current_user, "CREATE_FLIGHT", "Flight", flight.id, f"Flight: {flight.flight_number}")
    
    return flight


@router.put("/flights/{flight_id}", response_model=FlightResponse)
def update_flight(
    flight_id: int,
    flight_data: FlightUpdate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Update a flight (Admin: any flight, Staff: only flights of assigned airplane)"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Check access
    require_flight_access(current_user, flight_id, db)
    
    # Track changes for logging
    changes = []
    
    # Check for delay logic BEFORE applying updates
    if flight_data.departure_time and flight.departure_time:
        # If new departure time is LATER than old departure time -> DELAYED
        if flight_data.departure_time > flight.departure_time:
             flight.status = FlightStatus.DELAYED
             changes.append("Status: Automatically set to DELAYED due to time change")

    update_data = flight_data.dict(exclude_unset=True)
    
    # Check airplane status if airplane is being changed
    if 'airplane_id' in update_data and update_data['airplane_id'] != flight.airplane_id:
        new_airplane = db.query(Airplane).filter(Airplane.id == update_data['airplane_id']).first()
        if not new_airplane:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="New airplane not found"
            )
        if new_airplane.status != AirplaneStatus.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Airplane {new_airplane.model} is not active (Status: {new_airplane.status.value})"
            )

    time_changed = False
    old_dep_time = flight.departure_time
    
    for field, value in update_data.items():
        old_value = getattr(flight, field, None)
        # Skip status update if we just set it to DELAYED manually above and the user didn't explicitly send a status
        if field == 'status' and flight.status == FlightStatus.DELAYED and 'status' not in flight_data.dict(exclude_unset=True):
             continue
             
        if field in ['category_prices', 'category_allocations'] and value is not None:
            import json
            value = json.dumps(value)
            
        setattr(flight, field, value)
        if old_value != value:
            changes.append(f"{field}: {old_value} -> {value}")
            if field in ['departure_time', 'arrival_time']:
                time_changed = True
    
    # Auto-update status based on new times (this might override DELAYED if it falls into Boarding window immediately)
    # But per user request: "if i change... status must be delayed". 
    # Let's say explicit time change to later takes precedence as "DELAYED" until auto-logic picks it up later?
    # Actually, if I delay it to next week, it shouldn't be "Boarding" now.
    # The auto-logic handles: Boarding (1hr before), Departed, Landed.
    # If I delay it 1 hour, it might still be "Scheduled".
    # User said: "must be delayed".
    # So we let the manual set to DELAYED happen. The auto logic only touches Boarding/Departed/Landed.
    
    if time_changed:
        from app.models.announcement import Announcement, AnnouncementType
        from app.models.airport import Airport
        
        origin = db.query(Airport).filter(Airport.id == flight.origin_airport_id).first()
        destination = db.query(Airport).filter(Airport.id == flight.destination_airport_id).first()
        origin_code = origin.code if origin else "---"
        dest_code = destination.code if destination else "---"
        
        is_delayed = flight.departure_time > old_dep_time if old_dep_time else False
        ann_type = AnnouncementType.DELAY if is_delayed else AnnouncementType.GENERAL
        title_prefix = "⚠️ Flight Delayed" if is_delayed else "📅 Schedule Change"
        
        announcement = Announcement(
            flight_id=flight.id,
            type=ann_type,
            title=f"{title_prefix} - {flight.flight_number}",
            message=f"The schedule for flight {flight.flight_number} from {origin_code} to {dest_code} has been updated. "
                    f"New departure time: {flight.departure_time.strftime('%H:%M')}. "
                    f"New arrival time: {flight.arrival_time.strftime('%H:%M')}.",
            created_at=datetime.utcnow()
        )
        db.add(announcement)
    
    # Notify passengers of detail changes
    if changes:
        from app.models.notification import Notification, NotificationType
        from app.models.booking import Booking, BookingStatus
        
        # Get all users with active bookings for this flight
        active_bookings = db.query(Booking).filter(
            Booking.flight_id == flight_id,
            Booking.status.in_([BookingStatus.HOLD, BookingStatus.CONFIRMED])
        ).all()
        
        unique_user_ids = {b.user_id for b in active_bookings}
        
        notification_msg = f"Flight {flight.flight_number} update: " + "; ".join(changes)
        
        for u_id in unique_user_ids:
            notif = Notification(
                user_id=u_id,
                type=NotificationType.FLIGHT_UPDATE,
                title=f"Flight Update: {flight.flight_number}",
                message=notification_msg
            )
    # If flight is cancelled, cancel all active bookings
    # Check if status was changed to CANCELLED in this update
    if getattr(flight, 'status') == FlightStatus.CANCELLED:
         # We need to check if it was already cancelled before this update? 
         # We didn't capture original status perfectly but changes list helps or we just ensure consistency.
         # Ideally we only do this if it wasn't cancelled before. 
         # But doing it idempotent is fine: cancel any active bookings if flight is cancelled.
        from app.models.booking import Booking, BookingStatus
        active_bookings = db.query(Booking).filter(
            Booking.flight_id == flight_id,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.HOLD])
        ).all()
        
        for b in active_bookings:
            b.status = BookingStatus.CANCELLED
            if f"Auto-cancelled booking {b.pnr}" not in changes:
                changes.append(f"Auto-cancelled booking {b.pnr}")

    db.commit()

    db.commit()
    db.refresh(flight)
    
    if changes:
        log_critical_action(current_user, "UPDATE_FLIGHT", "Flight", flight.id, f"Changes: {', '.join(changes)}")
    
    return flight


@router.get("/flights", response_model=List[FlightResponse])
def list_flights(
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List flights (Admin/Staff: all)"""
    flights = db.query(Flight).all()
    
    # Run auto-status update on all fetched flights
    
    # Run auto-status update on all fetched flights
    updates = False
    for flight in flights:
        if update_flight_status_based_on_time(flight, db):
            updates = True
            
    if updates:
        db.commit()
        # Refresh lists not strictly needed as obj is updated in place, but good practice if needed
        
    return flights


@router.delete("/flights/{flight_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_flight(
    flight_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete a flight (Admin: any flight, Staff: only flights of assigned airplane)"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Check access (Global)
    # require_flight_access(current_user, flight_id, db)
    pass
    
    log_critical_action(current_user, "DELETE_FLIGHT", "Flight", flight_id, f"Flight: {flight.flight_number}")
    
    db.delete(flight)
    db.commit()
    return None


# Announcement Management
@router.post("/announcements", response_model=AnnouncementResponse, status_code=status.HTTP_201_CREATED)
def create_announcement(
    announcement_data: AnnouncementCreate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create an announcement (Admin: any flight, Staff: only flights of assigned airplane)"""
    # Verify flight exists if flight_id is provided
    flight = None
    if announcement_data.flight_id:
        flight = db.query(Flight).filter(Flight.id == announcement_data.flight_id).first()
        if not flight:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Flight not found"
            )
    
    # Check access (Global)
    # require_flight_access(current_user, announcement_data.flight_id, db)
    pass
    
    announcement = Announcement(
        **announcement_data.dict(),
        created_at=datetime.utcnow()
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    
    details = f"Flight: {flight.flight_number}" if flight else "General Announcement"
    log_critical_action(current_user, "CREATE_ANNOUNCEMENT", "Announcement", announcement.id, details)
    
    return announcement


@router.delete("/announcements/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_announcement(
    announcement_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete an announcement (Global access for Staff/Admin)"""
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Announcement not found"
        )
    
    log_critical_action(current_user, "DELETE_ANNOUNCEMENT", "Announcement", announcement_id, f"Title: {announcement.title}")
    
    db.delete(announcement)
    db.commit()
    return None


@router.get("/announcements", response_model=List[AnnouncementResponse])
def list_announcements(
    flight_id: Optional[int] = None,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List announcements (Admin/Staff: global or filtered by flight)"""
    query = db.query(Announcement)
    
    # Global access for Staff - no filtering by assigned_airplane
    
    if flight_id:
        # Check access if flight_id is provided (Global now)
        # if current_user.role == UserRole.STAFF:
        #     require_flight_access(current_user, flight_id, db)
        query = query.filter(Announcement.flight_id == flight_id)
    
    announcements = query.order_by(Announcement.created_at.desc()).all()
    return announcements


# Booking Management
@router.get("/bookings", response_model=List[BookingResponse])
def list_bookings(
    flight_id: Optional[int] = None,
    pnr: Optional[str] = None,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List bookings (Admin/Staff: all or filtered)"""
    query = db.query(Booking)
    
    # Global access for Staff
    
    if flight_id:
        query = query.filter(Booking.flight_id == flight_id)
    
    if pnr:
        query = query.filter(Booking.pnr == pnr)
    
    bookings = query.all()
    return bookings


@router.get("/bookings/{booking_id}", response_model=BookingDetailResponse)
def get_booking(
    booking_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get booking details (Global access for Staff/Admin)"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Get payments
    from app.models.payment import Payment
    payments = db.query(Payment).filter(Payment.booking_id == booking_id).all()
    
    # Get check-ins
    from app.models.checkin import CheckIn
    check_ins = []
    for ticket in booking.tickets:
        check_in = db.query(CheckIn).filter(CheckIn.ticket_id == ticket.id).first()
        if check_in:
            check_ins.append({
                "id": check_in.id,
                "ticket_id": check_in.ticket_id,
                "checked_in_at": check_in.checked_in_at,
                "qr_code": check_in.qr_code
            })
    
    # Get flight info
    from app.models.flight import Flight
    from app.models.airport import Airport
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    origin_airport = db.query(Airport).filter(Airport.id == flight.origin_airport_id).first()
    destination_airport = db.query(Airport).filter(Airport.id == flight.destination_airport_id).first()
    
    from app.schemas.booking import BookingResponse
    from app.schemas.flight import FlightResponse
    
    booking_response = BookingResponse.model_validate(booking)
    flight_response = FlightResponse.model_validate(flight)
    
    return {
        **booking_response.model_dump(),
        "payments": [{
            "id": p.id,
            "amount": p.amount,
            "method": p.method.value,
            "status": p.status.value,
            "transaction_id": p.transaction_id,
            "created_at": p.created_at
        } for p in payments],
        "check_ins": check_ins,
        "flight": flight_response.model_dump()
    }


@router.put("/bookings/{booking_id}/cancel")
def cancel_booking(
    booking_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Cancel a booking (Admin: any, Staff: only bookings for flights of assigned airplane)"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check access (Global)
    # require_booking_access(current_user, booking_id, db)
    pass
    
    # Get flight
    flight = db.query(Flight).filter(Flight.id == booking.flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Flight not found"
        )
    
    # Booking cancellation rules: Cannot cancel if DEPARTED or LANDED (unless admin override)
    if flight.status in [FlightStatus.DEPARTED, FlightStatus.LANDED]:
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel booking for {flight.status.value.lower()} flight. Only admin can override."
            )
        # Admin override allowed - log it
        log_critical_action(
            current_user, "CANCEL_BOOKING_ADMIN_OVERRIDE", "Booking", booking_id,
            f"Flight status: {flight.status.value}, PNR: {booking.pnr}"
        )
    
    from app.models.booking import BookingStatus
    booking.status = BookingStatus.CANCELLED
    db.commit()
    
    log_critical_action(current_user, "CANCEL_BOOKING", "Booking", booking_id, f"PNR: {booking.pnr}")


@router.delete("/bookings/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_booking_permanently(
    booking_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Permanently delete a booking (Admin/Staff only)"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check if delete is allowed for active bookings (Admin only if confirmed/hold?)
    # For now, allow staff to delete anything if they have access to this route
    
    pnr = booking.pnr
    db.delete(booking)
    db.commit()
    
    log_critical_action(current_user, "PERMANENT_DELETE_BOOKING", "Booking", booking_id, f"PNR: {pnr}")
    return None
    
    return {"message": "Booking cancelled successfully"}


@router.put("/tickets/{ticket_id}/seat")
def reassign_seat(
    ticket_id: int,
    new_seat: str,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Reassign seat for a ticket (Admin: any, Staff: only tickets for flights of assigned airplane)"""
    from app.models.booking import Ticket
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ticket not found"
        )
    
    # Get booking and check access
    booking = db.query(Booking).filter(Booking.id == ticket.booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    # Check access (Global)
    # require_booking_access(current_user, booking.id, db)
    pass
    
    # Get flight and check seat availability
    from app.services.seat_hold import get_available_seats
    available_seats = get_available_seats(db, booking.flight_id, include_held=False)
    
    if new_seat not in available_seats:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Seat does not exist"
        )
    
    old_seat = ticket.seat_number
    if not available_seats[new_seat]["available"]:
        # Admin can override seat availability
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Seat is not available. Only admin can override."
            )
        # Admin override - log it
        log_critical_action(
            current_user, "REASSIGN_SEAT_ADMIN_OVERRIDE", "Ticket", ticket_id,
            f"Seat: {old_seat} -> {new_seat} (seat was not available)"
        )
    
    ticket.seat_number = new_seat
    db.commit()
    
    log_critical_action(
        current_user, "REASSIGN_SEAT", "Ticket", ticket_id,
        f"Seat: {old_seat} -> {new_seat}, Booking: {booking.pnr}"
    )
    
    return {"message": "Seat reassigned successfully"}


# ==================== AIRPORT CRUD (Moved from Admin) ====================

@router.get("/airports", response_model=List[AirportResponse])
def list_airports(
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """List airports (Staff Global)"""
    airports = db.query(Airport).all()
    return airports


@router.post("/airports", response_model=AirportResponse, status_code=status.HTTP_201_CREATED)
def create_airport(
    airport_data: AirportCreate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Create a new airport (Staff Global)"""
    # Check for duplicate code
    existing = db.query(Airport).filter(Airport.code == airport_data.code.upper()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Airport with code {airport_data.code.upper()} already exists"
        )
    
    airport = Airport(
        code=airport_data.code.upper(),
        name=airport_data.name,
        city=airport_data.city,
        country=airport_data.country,
        created_by=current_user.id
    )
    db.add(airport)
    db.commit()
    db.refresh(airport)
    
    return airport


@router.put("/airports/{airport_id}", response_model=AirportResponse)
def update_airport(
    airport_id: int,
    airport_data: AirportUpdate,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Update an airport (Staff Global)"""
    airport = db.query(Airport).filter(Airport.id == airport_id).first()
    if not airport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airport not found"
        )
    
    # Global access for Staff - no ownership check
    
    update_data = airport_data.dict(exclude_unset=True)
    
    # Check for duplicate code if updating code
    if "code" in update_data:
        update_data["code"] = update_data["code"].upper()
        existing = db.query(Airport).filter(
            Airport.code == update_data["code"],
            Airport.id != airport_id
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Airport with code {update_data['code']} already exists"
            )
    
    for field, value in update_data.items():
        setattr(airport, field, value)
    
    db.commit()
    db.refresh(airport)
    
    return airport


@router.delete("/airports/{airport_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_airport_staff(
    airport_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Delete an airport (Staff Global)"""
    airport = db.query(Airport).filter(Airport.id == airport_id).first()
    if not airport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airport not found"
        )
    
    # Global access for Staff - no ownership check
    
    # Check if airport is used by any flights
    from app.models.flight import Flight
    flights_using = db.query(Flight).filter(
        (Flight.origin_airport_id == airport_id) | 
        (Flight.destination_airport_id == airport_id)
    ).first()
    
    if flights_using:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete airport that is used by existing flights"
        )
    
    db.delete(airport)
    db.commit()
    
    return None


@router.get("/airports/{airport_id}/flights")
def get_airport_flights(
    airport_id: int,
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all active flights for an airport (arrivals and departures)"""
    airport = db.query(Airport).filter(Airport.id == airport_id).first()
    if not airport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airport not found"
        )
    
    # Get departure flights (origin = this airport)
    departures = db.query(Flight).filter(
        Flight.origin_airport_id == airport_id,
        Flight.status != FlightStatus.CANCELLED
    ).order_by(Flight.departure_time).all()
    
    # Get arrival flights (destination = this airport)
    arrivals = db.query(Flight).filter(
        Flight.destination_airport_id == airport_id,
        Flight.status != FlightStatus.CANCELLED
    ).order_by(Flight.arrival_time).all()
    
    # Auto-update statuses
    for flight in departures + arrivals:
        update_flight_status_based_on_time(flight, db)
    db.commit()
    
    # Helper to format flight data
    def format_flight(flight, is_departure):
        other_airport_id = flight.destination_airport_id if is_departure else flight.origin_airport_id
        other_airport = db.query(Airport).filter(Airport.id == other_airport_id).first()
        airplane = db.query(Airplane).filter(Airplane.id == flight.airplane_id).first()
        
        return {
            "id": flight.id,
            "flight_number": flight.flight_number,
            "status": flight.status.value,
            "departure_time": flight.departure_time.isoformat(),
            "arrival_time": flight.arrival_time.isoformat(),
            "gate": flight.gate,
            "terminal": flight.terminal,
            "other_airport": {
                "id": other_airport.id if other_airport else None,
                "code": other_airport.code if other_airport else "---",
                "city": other_airport.city if other_airport else "Unknown"
            },
            "airplane": {
                "id": airplane.id if airplane else None,
                "model": airplane.model if airplane else "Unknown",
                "registration": airplane.registration_number if airplane else "---"
            }
        }
    
    return {
        "airport": {
            "id": airport.id,
            "code": airport.code,
            "name": airport.name,
            "city": airport.city,
            "country": airport.country
        },
        "departures": [format_flight(f, True) for f in departures],
        "arrivals": [format_flight(f, False) for f in arrivals],
        "summary": {
            "total_departures": len(departures),
            "total_arrivals": len(arrivals),
            "boarding_now": len([f for f in departures if f.status == FlightStatus.BOARDING])
        }
    }
@router.get("/payments", response_model=List[PaymentDetailResponse])
def get_all_payments(
    current_user: User = Depends(get_current_staff),
    db: Session = Depends(get_db)
):
    """Get all payments in the system (Staff/Admin only)"""
    from app.models.payment import Payment
    from app.models.booking import Booking, Ticket
    from app.models.flight import Flight
    from app.models.airport import Airport
    
    payments = db.query(Payment).all()
    
    result = []
    for payment in payments:
        booking = payment.booking
        user = booking.user
        flight = booking.flight
        
        # Build detailed info
        from app.schemas.payment import PaymentResponse
        payment_data = PaymentResponse.model_validate(payment).model_dump()
        
        payment_data['user_info'] = {
            "id": user.id,
            "email": user.email,
            "role": user.role
        }
        
        payment_data['booking_info'] = {
            "id": booking.id,
            "pnr": booking.pnr,
            "status": booking.status
        }
        
        payment_data['flight_info'] = {
            "id": flight.id,
            "flight_number": flight.flight_number,
            "origin": flight.origin_airport.code,
            "destination": flight.destination_airport.code,
            "departure_time": flight.departure_time.isoformat()
        }
        
        result.append(PaymentDetailResponse(**payment_data))
        
    return result
