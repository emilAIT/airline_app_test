from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import schemas, models
from ..database import get_db
from ..services import checkin_service
from ..auth import get_current_passenger

router = APIRouter(prefix="/checkin", tags=["Check-in"])


@router.post("/", status_code=status.HTTP_201_CREATED)
def check_in(
    checkin_data: schemas.CheckInCreate,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Check in for a flight"""
    # Verify ticket belongs to user's booking
    ticket = db.query(models.Ticket).filter(models.Ticket.id == checkin_data.ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    if ticket.booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    checkin_service.check_in_ticket(db, checkin_data.ticket_id)
    return {"message": "Check-in successful"}


@router.get("/boarding-pass/{ticket_id}", response_model=schemas.BoardingPassResponse)
def get_boarding_pass(
    ticket_id: int,
    current_user = Depends(get_current_passenger),
    db: Session = Depends(get_db)
):
    """Get boarding pass for a checked-in ticket"""
    # Verify ticket belongs to user's booking
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    if ticket.booking.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden"
        )
    
    return checkin_service.get_boarding_pass(db, ticket_id)

