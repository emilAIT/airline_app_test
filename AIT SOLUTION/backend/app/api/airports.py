from fastapi import APIRouter, Depends
from sqlmodel import Session, select
from typing import List
from app.database import get_session
from app.models import Airport, User, AirportRead
from app.core.deps import get_current_user
from app.services.all_services import AirportService

router = APIRouter(prefix="/airports", tags=["airports"])

@router.get("/", response_model=List[AirportRead])
def list_airports(session: Session = Depends(get_session)):
    service = AirportService(session)
    return service.get_airports()

@router.post("/")
def create_airport(
    data: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = AirportService(session)
    return service.create_airport(data, current_user)
