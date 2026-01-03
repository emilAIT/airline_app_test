from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_user
from app.models.all_models import User, Booking, UserRole, BookingStatus
from app.schemas.schemas import BookingCreate, BookingOut, BookingDetailOut, TicketOut, CancellationInfo, RefundRequest, RefundResponse
from typing import List
from app.services.booking_service import create_booking, cancel_booking

# FILE: bookings.py
# PURPOSE: Handles flight booking creation, retrieval, and cancellation
# SCOPE: Passenger booking management API endpoints

router = APIRouter(prefix="/bookings", tags=["Bookings"])


# FUNCTION: create_booking_endpoint
# PURPOSE: Creates a new flight booking with passenger tickets
# ENDPOINT: POST /bookings/ (accepts both /bookings and /bookings/)
# CALLED BY: Flutter BookingScreen
# DEPENDS ON: BookingService.create_booking, PassengerProfile validation
@router.post("/", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
@router.post("", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def create_booking_endpoint(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new booking"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403, detail="Only passengers can create bookings")

    # Check if profile is complete
    from app.models.all_models import PassengerProfile
    profile = db.query(PassengerProfile).filter(
        PassengerProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(
            status_code=400,
            detail="Profile must be completed before booking. Please create your profile first."
        )

    required_fields = ["passport_number",
                       "phone_number", "nationality", "date_of_birth"]
    missing = [field for field in required_fields if not getattr(
        profile, field, None)]
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"Profile incomplete. Missing fields: {', '.join(missing)}"
        )

    try:
        tickets_data = [{"passenger_name": t.passenger_name,
                         "seat_number": t.seat_number} for t in booking_data.tickets]
        booking = create_booking(
            db=db,
            user_id=current_user.id,
            flight_id=booking_data.flight_id,
            tickets_data=tickets_data,
            hold_seats=True
        )
        return booking
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ENDPOINT: GET /bookings/ (returns all user bookings)
# PURPOSE: Get current user's bookings with automatic expiration cleanup
# IMPORTANT: Runs expire_bookings() to mark expired holds before returning
@router.get("/", response_model=List[BookingOut])
@router.get("", response_model=List[BookingOut])  # Support both with/without slash
def get_my_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's bookings (includes expired and completed)"""
    # Cleanup expired bookings first
    from app.services.booking_service import expire_bookings
    expire_bookings(db)
    
    bookings = db.query(Booking).filter(
        Booking.user_id == current_user.id).order_by(Booking.created_at.desc()).all()
    return bookings


@router.get("/{booking_id}", response_model=BookingDetailOut)
def get_booking(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get booking details"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Check ownership or staff access
    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to view this booking")

    return booking


@router.get("/pnr/{pnr}", response_model=BookingDetailOut)
def get_booking_by_pnr(
    pnr: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get booking by PNR code"""
    booking = db.query(Booking).filter(Booking.pnr == pnr).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Check ownership or staff access
    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to view this booking")

    return booking


@router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_booking_endpoint(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel a booking"""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Check ownership or staff access
    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to cancel this booking")

    # Check if flight has departed
    from app.models.all_models import FlightStatus
    if booking.flight.status == FlightStatus.DEPARTED:
        raise HTTPException(
            status_code=400, detail="Cannot cancel booking for departed flight")

    try:
        cancel_booking(db, booking_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return None


@router.get("/ticket/{ticket_id}", response_model=dict)
def get_ticket(
    ticket_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get ticket details with flight information"""
    from app.models.all_models import Ticket

    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # Check ownership - user must own the booking
    if ticket.booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to view this ticket")

    # Return ticket with flight details
    return {
        "id": ticket.id,
        "ticket_number": ticket.ticket_number,
        "seat_number": ticket.seat_number,
        "passenger_name": ticket.passenger_name,
        "booking_id": ticket.booking_id,
        "flight": {
            "id": ticket.booking.flight.id,
            "flight_number": ticket.booking.flight.flight_number,
            "departure_time": ticket.booking.flight.departure_time.isoformat(),
            "arrival_time": ticket.booking.flight.arrival_time.isoformat(),
            "origin": {
                "id": ticket.booking.flight.origin.id,
                "code": ticket.booking.flight.origin.code,
                "name": ticket.booking.flight.origin.name,
                "city": ticket.booking.flight.origin.city,
                "country": ticket.booking.flight.origin.country,
            },
            "destination": {
                "id": ticket.booking.flight.destination.id,
                "code": ticket.booking.flight.destination.code,
                "name": ticket.booking.flight.destination.name,
                "city": ticket.booking.flight.destination.city,
                "country": ticket.booking.flight.destination.country,
            },
        }
    }


# FUNCTION: get_cancellation_info
# PURPOSE: Check if booking can be cancelled and calculate refund
@router.get("/{booking_id}/cancel-info", response_model=CancellationInfo)
@router.get("/{booking_id}/cancel-info/", response_model=CancellationInfo)
def get_cancellation_info(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to view this booking")

    from app.services.cancellation_service import evaluate_cancellation
    result = evaluate_cancellation(db, booking)
    
    return {
        "allowed": result["allowed"],
        "description": result["description"],
        "refund_amount": result["refund_amount"]
    }


# FUNCTION: cancel_booking_with_refund
# PURPOSE: Cancel booking and process refund
@router.post("/{booking_id}/cancel", response_model=RefundResponse)
@router.post("/{booking_id}/cancel/", response_model=RefundResponse)
def cancel_booking_with_refund(
    booking_id: int,
    refund_req: RefundRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized to cancel this booking")

    from app.services.cancellation_service import evaluate_cancellation, process_refund, get_active_policy
    
    # Get Policy
    policy = get_active_policy(db)
    if not policy:
        raise HTTPException(status_code=400, detail="No active cancellation policy")

    # Check method allowed by policy
    if refund_req.method == "CARD" and not policy.allow_card_refund:
        raise HTTPException(status_code=400, detail="Card refunds are currently disabled by admin")
    if refund_req.method == "APPLE_PAY" and not policy.allow_apple_pay_refund:
        raise HTTPException(status_code=400, detail="Apple Pay refunds are currently disabled by admin")

    # Re-evaluate eligibility
    info = evaluate_cancellation(db, booking)
    if not info["allowed"]:
        raise HTTPException(
            status_code=400, 
            detail=f"Cancellation not allowed: {info['description']}"
        )

    refund_amount = info["refund_amount"]

    # Process Refund (Mock) - creates Refund record
    card_last4 = refund_req.refund_card_number[-4:] if refund_req.refund_card_number else None
    process_refund(
        db, booking, 
        method=refund_req.method, 
        card_last4=card_last4,
        card_holder=refund_req.card_holder
    )
    
    # Release seats
    for ticket in booking.tickets:
        from app.models.all_models import Seat
        seat = db.query(Seat).filter(
            Seat.flight_id == booking.flight_id,
            Seat.seat_number == ticket.seat_number
        ).first()
        if seat:
            seat.is_available = True
            db.add(seat)
    db.commit()

    # Build message
    if refund_req.method == "APPLE_PAY":
        message = f"Booking cancelled. Refund of ${refund_amount} will be processed to your original Apple Pay method."
    else:
        message = f"Booking cancelled. Refund of ${refund_amount} processed to card ending in {card_last4}."

    return {
        "status": "CANCELLED",
        "refund_amount": refund_amount,
        "message": message
    }

