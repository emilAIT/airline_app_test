from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from schemas.airplane import AirplaneCreate, AirplaneResponse
from schemas.announcement import AnnouncementCreate, AnnouncementResponse
from core.dependencies import get_db, require_admin
from models.airplane import Airplane
from services.announcement_service import create_announcement

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.post(
    "/airplanes",
    response_model=AirplaneResponse,
)
def create_airplane(
    data: AirplaneCreate,
    db: Session = Depends(get_db),
    user=Depends(require_admin),
):
    airplane = Airplane(**data.model_dump())
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    return airplane


@router.post(
    "/announcements",
    response_model=AnnouncementResponse,
)
def create_announcement_endpoint(
    data: AnnouncementCreate,
    db: Session = Depends(get_db),
    user=Depends(require_admin),
):
    return create_announcement(db=db, announcement_data=data)
