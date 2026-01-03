from fastapi import APIRouter, Depends, HTTPException
from typing import Any

from app import crud
from app.api.deps import SessionDep, CurrentUser, CurrentStaffUser
from app.models import (
    Announcement,
    AnnouncementCreate,
    AnnouncementUpdate,
    AnnouncementPublic,
    AnnouncementsPublic,
    UserRole,
)

router = APIRouter(prefix="/announcements", tags=["announcements"])


# =====================
# CREATE (STAFF)
# =====================
@router.post(
    "",
    response_model=AnnouncementPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def create_announcement(
    *,
    session: SessionDep,
    announcement_in: AnnouncementCreate,
    current_user: CurrentUser,
) -> Any:
    try:
        return crud.create_announcement(
            session=session,
            current_user=current_user,
            announcement_in=announcement_in,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# =====================
# ALL ANNOUNCEMENTS (STAFF ONLY) - ДОЛЖНО БЫТЬ ПЕРЕД /{announcement_id}
# =====================
@router.get(
    "/all",
    response_model=AnnouncementsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def all_announcements(
    *,
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get all announcements (STAFF only).
    """
    from sqlmodel import select, func
    from app.models import Announcement
    
    print(f"[API] GET /announcements/all - skip={skip}, limit={limit}")
    
    statement = (
        select(Announcement)
        .offset(skip)
        .limit(limit)
        .order_by(Announcement.created_at.desc())
    )
    announcements = session.exec(statement).all()
    
    # Get total count
    count = session.exec(select(func.count()).select_from(Announcement)).one()
    
    print(f"[API] Returning {len(announcements)} announcements (total count: {count})")
    
    return AnnouncementsPublic(
        data=announcements,
        count=count,
    )


# =====================
# MY ANNOUNCEMENTS - ДОЛЖНО БЫТЬ ПЕРЕД /{announcement_id}
# =====================
@router.get(
    "/me",
    response_model=AnnouncementsPublic,
)
def my_announcements(
    *,
    session: SessionDep,
    current_user: CurrentUser,
) -> Any:
    """
    For PASSENGER: returns announcements for their bookings.
    For STAFF: returns all announcements (same as /all).
    """
    if current_user.role == UserRole.STAFF:
        # Staff sees all announcements
        from sqlmodel import select
        from app.models import Announcement
        
        statement = (
            select(Announcement)
            .order_by(Announcement.created_at.desc())
        )
        announcements = session.exec(statement).all()
    else:
        # Passenger sees only their announcements
        announcements = crud.get_user_announcements(
            session=session,
            current_user=current_user,
        )

    return AnnouncementsPublic(
        data=announcements,
        count=len(announcements),
    )


# =====================
# BY FLIGHT - ДОЛЖНО БЫТЬ ПЕРЕД /{announcement_id}
# =====================
@router.get(
    "/flight/{flight_id}",
    response_model=AnnouncementsPublic,
)
def announcements_by_flight(
    *,
    session: SessionDep,
    flight_id: str,
    current_user: CurrentUser,
) -> Any:
    try:
        announcements = crud.get_announcements_by_flight(
            session=session,
            current_user=current_user,
            flight_id=flight_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))

    return AnnouncementsPublic(
        data=announcements,
        count=len(announcements),
    )


# =====================
# READ ONE - ДОЛЖНО БЫТЬ ПОСЛЕДНИМ, так как ловит все остальные пути
# =====================
@router.get("/{announcement_id}", response_model=AnnouncementPublic)
def read_announcement(
    *,
    session: SessionDep,
    announcement_id: str,
    current_user: CurrentUser,
) -> Any:
    announcement = crud.get_announcement(
        session=session,
        announcement_id=announcement_id,
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    # пассажир может видеть только если есть booking на этот flight
    if current_user.role != UserRole.STAFF:
        try:
            crud.get_announcements_by_flight(
                session=session,
                current_user=current_user,
                flight_id=announcement.flight_id,
            )
        except ValueError:
            raise HTTPException(status_code=403, detail="Not enough permissions")

    return announcement


# =====================
# UPDATE (STAFF)
# =====================
@router.patch(
    "/{announcement_id}",
    response_model=AnnouncementPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_announcement(
    *,
    session: SessionDep,
    announcement_id: str,
    announcement_in: AnnouncementUpdate,
    current_user: CurrentUser,
) -> Any:
    announcement = crud.get_announcement(
        session=session,
        announcement_id=announcement_id,
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    try:
        return crud.update_announcement(
            session=session,
            current_user=current_user,
            announcement=announcement,
            announcement_in=announcement_in,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# =====================
# DELETE (STAFF)
# =====================
@router.delete(
    "/{announcement_id}",
    status_code=204,
    dependencies=[Depends(CurrentStaffUser)],
)
def delete_announcement(
    *,
    session: SessionDep,
    announcement_id: str,
    current_user: CurrentUser,
) -> None:
    announcement = crud.get_announcement(
        session=session,
        announcement_id=announcement_id,
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    crud.delete_announcement(
        session=session,
        current_user=current_user,
        announcement=announcement,
    )
