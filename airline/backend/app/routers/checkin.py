from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.auth_handler import get_current_user
from app.models.all_models import User, Ticket, UserRole
from app.schemas.schemas import CheckInOut, CheckInCreate, BoardingPassOut
from app.services.checkin_service import create_check_in, get_boarding_pass

router = APIRouter(prefix="/checkin", tags=["Check-in"])


@router.post("/", response_model=CheckInOut, status_code=status.HTTP_201_CREATED)
@router.post("", response_model=CheckInOut, status_code=status.HTTP_201_CREATED)
def check_in(
    checkin_data: CheckInCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check in for a flight"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can check in")

    ticket = db.query(Ticket).filter(Ticket.id == checkin_data.ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # Check ownership
    if ticket.booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to check in for this ticket")

    try:
        check_in = create_check_in(db, checkin_data.ticket_id)
        return check_in
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/ticket/{ticket_id}/boarding-pass", response_model=BoardingPassOut)
def get_boarding_pass_endpoint(
    ticket_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get boarding pass for a checked-in ticket"""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(status_code=403, detail="Only passengers can view boarding passes")

    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # Check ownership
    if ticket.booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this boarding pass")

    try:
        boarding_pass = get_boarding_pass(db, ticket_id)
        return boarding_pass
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

