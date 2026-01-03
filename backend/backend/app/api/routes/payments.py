from fastapi import APIRouter, Depends, HTTPException, Header
from typing import Any
from sqlmodel import select, func

from app import crud
from app.api.deps import SessionDep, CurrentUser, CurrentStaffUser
from app.models import (
    PaymentCreate,
    PaymentPublic,
    PaymentsPublic,
    PaymentStatus,
    Payment,
)

router = APIRouter(prefix="/payments", tags=["payments"])


@router.get(
    "/",
    response_model=PaymentsPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def read_all_payments(
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get all payments (STAFF only).
    """
    payments = crud.get_all_payments(
        session=session,
        skip=skip,
        limit=limit,
    )
    
    # Get total count
    count = session.exec(select(func.count()).select_from(Payment)).one()
    
    return PaymentsPublic(data=payments, count=count)


@router.post("", response_model=PaymentPublic)
def create_payment(
    *,
    session: SessionDep,
    payment_in: PaymentCreate,
    current_user: CurrentUser,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
) -> Any:
    """
    Create payment (idempotent).
    Successful payment → booking CONFIRMED.
    """
    print(f"[API] POST /payments - User: {current_user.email}, Booking: {payment_in.booking_id}, Method: {payment_in.method}")

    booking = crud.get_booking(
        session=session,
        booking_id=payment_in.booking_id,
    )

    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")

    try:
        result = crud.create_payment(
            session=session,
            booking=booking,
            method=payment_in.method,
            idempotency_key=idempotency_key,
        )
        print(f"[API] Successfully created payment for booking PNR={booking.pnr}")
        return result
    except ValueError as e:
        print(f"[API] ERROR creating payment: {e}")
        raise HTTPException(status_code=400, detail=str(e))


# =====================
# READ ONE PAYMENT
# =====================
@router.get("/{payment_id}", response_model=PaymentPublic)
def read_payment(
    *,
    session: SessionDep,
    payment_id: str,
    current_user: CurrentUser,
) -> Any:
    payment = crud.get_payment(session=session, payment_id=payment_id)

    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")

    if payment.booking.user_id != current_user.id and current_user.role != "STAFF":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return payment


@router.get(
    "/booking/{booking_id}",
    response_model=PaymentsPublic,
)
def payments_by_booking(
    *,
    session: SessionDep,
    booking_id: str,
    current_user: CurrentUser,
) -> Any:
    booking = crud.get_booking(session=session, booking_id=booking_id)

    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.user_id != current_user.id and current_user.role != "STAFF":
        raise HTTPException(status_code=403, detail="Not enough permissions")

    payments = crud.get_payments_by_booking(
        session=session,
        booking_id=booking_id,
    )

    return PaymentsPublic(data=payments, count=len(payments))


@router.get("/me", response_model=PaymentsPublic)
def my_payments(
    *,
    session: SessionDep,
    current_user: CurrentUser,
) -> Any:
    payments = crud.get_user_payments(
        session=session,
        user_id=current_user.id,
    )

    return PaymentsPublic(data=payments, count=len(payments))


@router.patch(
    "/{payment_id}/status",
    response_model=PaymentPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_payment_status(
    *,
    session: SessionDep,
    payment_id: str,
    status: PaymentStatus,
) -> Any:
    """
    Mock payment processing:
    PAID → booking CONFIRMED
    """

    payment = crud.get_payment(session=session, payment_id=payment_id)

    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")

    try:
        return crud.update_payment_status(
            session=session,
            payment=payment,
            status=status,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
