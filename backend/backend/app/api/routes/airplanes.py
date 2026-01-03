from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import SQLModel, select

from app import crud
from app.api.deps import CurrentStaffUser, SessionDep
from app.models import (
    Airplane,
    AirplanePublic,
    AirplaneUpdate,
    SeatTemplate,
    SeatTemplateBase,
)

router = APIRouter(prefix="/airplanes", tags=["airplanes"])


# =====================
# PAYLOADS (BUSINESS CREATE)
# =====================

class AirplaneCreateRequest(SQLModel):
    model: str
    seat_map: List[SeatTemplateBase]


# =====================
# CREATE AIRPLANE + SEAT MAP (STAFF ONLY)
# =====================
@router.post(
    "",
    response_model=AirplanePublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def create_airplane(
    *,
    session: SessionDep,
    payload: AirplaneCreateRequest,
) -> Any:
    """
    Create airplane with seat templates (STAFF only).
    """

    if not payload.seat_map:
        raise HTTPException(
            status_code=400,
            detail="Seat map cannot be empty",
        )

    airplane = Airplane(
        model=payload.model,
        total_seats=len(payload.seat_map),
    )
    session.add(airplane)
    session.flush()  # получить airplane.id

    seat_templates = [
        SeatTemplate(
            airplane_id=airplane.id,
            row=seat.row,
            seat_label=seat.seat_label,
            category=seat.category,
        )
        for seat in payload.seat_map
    ]

    session.add_all(seat_templates)
    session.commit()
    session.refresh(airplane)

    return airplane


# =====================
# READ ALL (PUBLIC)
# =====================
@router.get("", response_model=list[AirplanePublic])
def read_airplanes(
    session: SessionDep,
) -> Any:
    return crud.get_airplanes(session=session)


# =====================
# READ ONE (PUBLIC)
# =====================
@router.get("/{airplane_id}", response_model=AirplanePublic)
def read_airplane(
    *,
    session: SessionDep,
    airplane_id: str,
) -> Any:
    airplane = crud.get_airplane(session=session, airplane_id=airplane_id)
    if not airplane:
        raise HTTPException(
            status_code=404,
            detail="Airplane not found",
        )
    return airplane


# =====================
# UPDATE (STAFF ONLY)
# =====================
@router.put(
    "/{airplane_id}",
    response_model=AirplanePublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_airplane(
    *,
    session: SessionDep,
    airplane_id: str,
    airplane_in: AirplaneUpdate,
) -> Any:
    db_airplane = crud.get_airplane(session=session, airplane_id=airplane_id)
    if not db_airplane:
        raise HTTPException(
            status_code=404,
            detail="Airplane not found",
        )

    return crud.update_airplane(
        session=session,
        db_airplane=db_airplane,
        airplane_in=airplane_in,
    )


# =====================
# DELETE (STAFF ONLY)
# =====================
@router.delete(
    "/{airplane_id}",
    dependencies=[Depends(CurrentStaffUser)],
)
def delete_airplane(
    *,
    session: SessionDep,
    airplane_id: str,
) -> Any:
    db_airplane = crud.get_airplane(session=session, airplane_id=airplane_id)
    if not db_airplane:
        raise HTTPException(
            status_code=404,
            detail="Airplane not found",
        )

    crud.delete_airplane(session=session, db_airplane=db_airplane)
    return {"ok": True}


# =====================
# PREVIEW SEAT MAP (STAFF ONLY)
# =====================
@router.get(
    "/{airplane_id}/seat-map",
    dependencies=[Depends(CurrentStaffUser)],
)
def preview_seat_map(
    *,
    session: SessionDep,
    airplane_id: str,
) -> Any:
    """
    Preview seat map for airplane (STAFF only).
    """

    airplane = crud.get_airplane(session=session, airplane_id=airplane_id)
    if not airplane:
        raise HTTPException(
            status_code=404,
            detail="Airplane not found",
        )

    seats = session.exec(
        select(SeatTemplate)
        .where(SeatTemplate.airplane_id == airplane_id)
        .order_by(SeatTemplate.row, SeatTemplate.seat_label)
    ).all()

    return {
        "airplane_id": airplane.id,
        "model": airplane.model,
        "total_seats": airplane.total_seats,
        "seat_map": seats,
    }

