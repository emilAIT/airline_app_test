from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import func, select

from app import crud
from app.api.deps import SessionDep, get_current_staff_user
from app.models import (
    Airport,
    AirportCreate,
    AirportUpdate,
    AirportPublic,
    AirportsPublic,
)

router = APIRouter(prefix="/airports", tags=["airports"])


# =====================
# READ ALL (PUBLIC)
# =====================
@router.get("/", response_model=AirportsPublic)
def read_airports(
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    List all available airports (public).
    """
    count = session.exec(
        select(func.count()).select_from(Airport)
    ).one()

    airports = session.exec(
        select(Airport)
        .offset(skip)
        .limit(limit)
    ).all()

    return AirportsPublic(data=airports, count=count)


# =====================
# READ ONE (PUBLIC)
# =====================
@router.get("/{airport_id}", response_model=AirportPublic)
def read_airport(
    airport_id: str,
    session: SessionDep,
) -> Any:
    airport = crud.get_airport(session=session, airport_id=airport_id)
    if not airport:
        raise HTTPException(status_code=404, detail="Airport not found")
    return airport


# =====================
# CREATE (STAFF ONLY)
# =====================
@router.post("/", response_model=AirportPublic)
def create_airport(
    *,
    session: SessionDep,
    airport_in: AirportCreate,
    _: Any = Depends(get_current_staff_user),
) -> Any:
    airport = Airport.model_validate(airport_in)
    return crud.create_airport(session=session, airport_in=airport)


# =====================
# UPDATE (STAFF ONLY)
# =====================
@router.put("/{airport_id}", response_model=AirportPublic)
def update_airport(
    *,
    session: SessionDep,
    airport_id: str,
    airport_in: AirportUpdate,
    _: Any = Depends(get_current_staff_user),
) -> Any:
    db_airport = crud.get_airport(session=session, airport_id=airport_id)
    if not db_airport:
        raise HTTPException(status_code=404, detail="Airport not found")

    return crud.update_airport(
        session=session,
        db_airport=db_airport,
        airport_in=airport_in,
    )



# =====================
# DELETE (STAFF ONLY)
# =====================
@router.delete("/{airport_id}")
def delete_airport(
    *,
    session: SessionDep,
    airport_id: str,
    _: Any = Depends(get_current_staff_user),
) -> Any:
    db_airport = crud.get_airport(session=session, airport_id=airport_id)
    if not db_airport:
        raise HTTPException(status_code=404, detail="Airport not found")

    crud.delete_airport(session=session, db_airport=db_airport)
    return {"ok": True}
