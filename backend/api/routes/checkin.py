from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from schemas.checkin import CheckInResponse
from db.session import get_db
from core.dependencies import require_passenger
from services.checkin_service import CheckInService

router = APIRouter(prefix="/check-in", tags=["CheckIn"])


@router.post(
    "/{ticket_id}",
    response_model=CheckInResponse,
)
def check_in(
    ticket_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_passenger),
):
    return CheckInService.check_in(
        db=db,
        ticket_id=ticket_id,
    )
