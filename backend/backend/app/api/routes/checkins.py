from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select

from app import crud
from app.api.deps import SessionDep, CurrentUser, CurrentStaffUser
from app.models import (
    CheckIn,
    CheckInCreate,
    CheckInPublic,
    CheckInsPublic,
    BoardingPass,
    BoardingPassPublic,
    Ticket,
    UserRole,
)


router = APIRouter(prefix="/checkins", tags=["checkins"])


# =====================
# CREATE CHECK-IN
# =====================
@router.post("", response_model=CheckInPublic)
def create_checkin(
    *,
    session: SessionDep,
    checkin_in: CheckInCreate,
    current_user: CurrentUser,
) -> Any:
    ticket = crud.get_ticket(
        session=session,
        ticket_id=checkin_in.ticket_id,
    )

    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    if ticket.booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your ticket")

    try:
        return crud.create_checkin(
            session=session,
            ticket=ticket,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# =====================
# READ ONE CHECK-IN
# =====================
@router.get("/{checkin_id}", response_model=CheckInPublic)
def read_checkin(
    *,
    session: SessionDep,
    checkin_id: str,
    current_user: CurrentUser,
) -> Any:
    checkin = crud.get_checkin(
        session=session,
        checkin_id=checkin_id,
    )

    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in not found")

    if (
        checkin.ticket.booking.user_id != current_user.id
        and current_user.role != UserRole.STAFF
    ):
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return checkin


# =====================
# CHECK-INS BY BOOKING
# =====================
@router.get(
    "/booking/{booking_id}",
    response_model=CheckInsPublic,
)
def checkins_by_booking(
    *,
    session: SessionDep,
    booking_id: str,
    current_user: CurrentUser,
) -> Any:
    booking = crud.get_booking(
        session=session,
        booking_id=booking_id,
    )

    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if (
        booking.user_id != current_user.id
        and current_user.role != UserRole.STAFF
    ):
        raise HTTPException(status_code=403, detail="Not enough permissions")

    checkins = session.exec(
        select(CheckIn)
        .join(CheckIn.ticket)
        .where(Ticket.booking_id == booking_id)
        .order_by(CheckIn.checked_in_at)
    ).all()

    return CheckInsPublic(
        data=checkins,
        count=len(checkins),
    )


# =====================
# CHECK-INS BY FLIGHT (STAFF)
# =====================
@router.get(
    "/flight/{flight_id}",
    response_model=CheckInsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def checkins_by_flight(
    *,
    session: SessionDep,
    flight_id: str,
) -> Any:
    checkins = crud.get_checkins_by_flight(
        session=session,
        flight_id=flight_id,
    )

    return CheckInsPublic(
        data=checkins,
        count=len(checkins),
    )


# =====================
# GET BOARDING PASS
# =====================
@router.get(
    "/{checkin_id}/boarding-pass",
    response_model=BoardingPassPublic,
)
def get_boarding_pass(
    *,
    session: SessionDep,
    checkin_id: str,
    current_user: CurrentUser,
) -> Any:
    checkin = crud.get_checkin(
        session=session,
        checkin_id=checkin_id,
    )

    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in not found")

    if (
        checkin.ticket.booking.user_id != current_user.id
        and current_user.role != UserRole.STAFF
    ):
        raise HTTPException(status_code=403, detail="Not enough permissions")

    boarding_pass = session.exec(
        select(BoardingPass)
        .where(BoardingPass.checkin_id == checkin.id)
    ).first()

    if not boarding_pass:
        raise HTTPException(status_code=404, detail="Boarding pass not found")

    return boarding_pass
