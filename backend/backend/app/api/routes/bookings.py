from fastapi import APIRouter, Depends, HTTPException
from typing import Any
from sqlmodel import select, func

from app import crud
from app.api.deps import CurrentUser, CurrentStaffUser, SessionDep
from app.models import BookingCreate, BookingPublic, BookingsPublic, Booking, UserRole

router = APIRouter(prefix="/bookings", tags=["bookings"])

@router.post("", response_model=BookingPublic)
def create_booking(
    *,
    session: SessionDep,
    booking_in: BookingCreate,
    current_user: CurrentUser,
) -> Any:
    print(f"[API] POST /bookings - User: {current_user.email}, Flight: {booking_in.flight_id}")
    try:
        result = crud.create_booking(
            session=session,
            user=current_user,
            booking_in=booking_in,
        )
        print(f"[API] Successfully created booking PNR={result.pnr}")
        return result
    except ValueError as e:
        print(f"[API] ERROR creating booking: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@router.get(
    "/",
    response_model=BookingsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def read_all_bookings(
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get all bookings (STAFF only).
    """
    bookings = crud.get_all_bookings(
        session=session,
        skip=skip,
        limit=limit,
    )
    
    # Get total count
    count = session.exec(select(func.count()).select_from(Booking)).one()
    
    return BookingsPublic(data=bookings, count=count)


@router.get("/me", response_model=BookingsPublic)
def my_bookings(
    *,
    session: SessionDep,
    current_user: CurrentUser,
) -> Any:
    bookings = crud.get_user_bookings(session=session, user_id=current_user.id)
    return BookingsPublic(data=bookings, count=len(bookings))


@router.get("/{booking_id}", response_model=BookingPublic)
def read_booking(
    *,
    session: SessionDep,
    booking_id: str,
    current_user: CurrentUser,
) -> Any:
    booking = crud.get_booking(session=session, booking_id=booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id and current_user.role != UserRole.STAFF:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return booking


@router.post("/{booking_id}/cancel", response_model=BookingPublic)
def cancel_booking(
    *,
    session: SessionDep,
    booking_id: str,
    current_user: CurrentUser,
) -> Any:
    print(f"[API] POST /bookings/{booking_id}/cancel - User: {current_user.email}")
    booking = crud.get_booking(session=session, booking_id=booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")

    result = crud.cancel_booking(session=session, booking=booking)
    print(f"[API] Successfully cancelled booking PNR={result.pnr}")
    return result


@router.get(
    "/search/by-pnr/{pnr}",
    response_model=BookingPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def search_by_pnr(
    *,
    session: SessionDep,
    pnr: str,
) -> Any:
    booking = session.exec(
        select(Booking).where(Booking.pnr == pnr)
    ).first()

    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    return booking


@router.get(
    "/flight/{flight_id}",
    response_model=BookingsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def read_bookings_by_flight(
    *,
    session: SessionDep,
    flight_id: str,
) -> Any:
    """
    Get all bookings for a specific flight (STAFF only).
    """
    bookings = session.exec(
    select(Booking).where(Booking.flight_id == flight_id)
    ).all()

    return BookingsPublic(
        data=bookings,
        count=len(bookings),
    )
