from fastapi import APIRouter, HTTPException, Depends
from typing import Any

from app import crud
from app.api.deps import SessionDep, CurrentUser, CurrentStaffUser, get_current_staff_user
from app.models import (
    SeatHold,
    SeatHoldCreate,
    SeatHoldPublic,
    SeatHoldsPublic,
)

router = APIRouter(prefix="/seat-holds", tags=["seat-holds"])


@router.post("", response_model=SeatHoldPublic)
def create_seat_hold(
    *,
    session: SessionDep,
    hold_in: SeatHoldCreate,
    current_user: CurrentUser,
) -> Any:
    """
    Hold seat for 10 minutes.
    """

    try:
        return crud.create_seat_hold(
            session=session,
            flight_id=hold_in.flight_id,
            flight_seat_id=hold_in.flight_seat_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get(
    "/flight/{flight_id}",
    response_model=SeatHoldsPublic,
)
def get_holds_by_flight(
    *,
    session: SessionDep,
    flight_id: str,
    current_user: CurrentUser,
) -> Any:
    holds = crud.get_holds_by_flight(
        session=session,
        flight_id=flight_id,
    )

    return SeatHoldsPublic(
        data=holds,
        count=len(holds),
    )


@router.delete("/{flight_seat_id}")
def release_seat_hold(
    *,
    session: SessionDep,
    flight_seat_id: str,
    current_user: CurrentUser,
) -> Any:
    """
    Release seat hold manually.
    """

    crud.release_seat_hold(
        session=session,
        flight_seat_id=flight_seat_id,
    )

    return {"message": "Seat hold released"}


@router.post(
    "/cleanup",
    dependencies=[Depends(get_current_staff_user)],
)
def cleanup_expired_holds(
    *,
    session: SessionDep,
) -> Any:
    """
    Cleanup expired seat holds.
    """

    crud.cleanup_expired_seat_holds(session=session)
    return {"message": "Expired seat holds cleaned up"}
