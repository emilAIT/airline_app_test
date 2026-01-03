from fastapi import APIRouter, Depends
from sqlmodel import Session
from typing import List
from app.database import get_session
from app.models import Airplane, User
from app.core.deps import get_current_user
from app.services.all_services import AirplaneService

router = APIRouter(prefix="/airplanes", tags=["airplanes"])

@router.get("/", response_model=List[Airplane])
def list_airplanes(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = AirplaneService(session)
    return service.get_airplanes(current_user)

@router.post("/")
def create_airplane(
    data: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = AirplaneService(session)
    return service.create_airplane(data, current_user)

@router.delete("/{airplane_id}")
def delete_airplane(
    airplane_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = AirplaneService(session)
    return service.delete_airplane(airplane_id, current_user)
