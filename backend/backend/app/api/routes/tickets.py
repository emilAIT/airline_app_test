from fastapi import APIRouter, Depends, HTTPException
from typing import Any
from sqlmodel import select, func

from app import crud
from app.api.deps import CurrentUser, CurrentStaffUser, SessionDep
from app.models import Ticket, TicketPublic, TicketsPublic

router = APIRouter(prefix="/tickets", tags=["tickets"])


@router.get(
    "/",
    response_model=TicketsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def read_all_tickets(
    *,
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get all tickets (STAFF only).
    """
    tickets = crud.get_all_tickets(
        session=session,
        skip=skip,
        limit=limit,
    )
    
    # Get total count
    count = session.exec(select(func.count()).select_from(Ticket)).one()
    
    return TicketsPublic(data=tickets, count=count)


@router.get("/{ticket_id}", response_model=TicketPublic)
def read_ticket(
    *,
    session: SessionDep,
    ticket_id: str,
    current_user: CurrentUser,
) -> Any:
    ticket = crud.get_ticket(session=session, ticket_id=ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    if ticket.booking.user_id != current_user.id and current_user.role != "STAFF":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return ticket


@router.get(
    "/booking/{booking_id}",
    response_model=list[TicketPublic],
)
def read_tickets_by_booking(
    *,
    session: SessionDep,
    booking_id: str,
    current_user: CurrentUser,
) -> Any:
    tickets = crud.get_tickets_by_booking(
        session=session,
        booking_id=booking_id,
    )

    if not tickets:
        raise HTTPException(status_code=404, detail="No tickets found")

    booking = tickets[0].booking
    if booking.user_id != current_user.id and current_user.role != "STAFF":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return tickets


@router.get(
    "/search/by-number/{ticket_number}",
    response_model=TicketPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def search_ticket_by_number(
    *,
    session: SessionDep,
    ticket_number: str,
) -> Any:
    ticket = crud.get_ticket_by_number(
        session=session,
        ticket_number=ticket_number,
    )

    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    return ticket


