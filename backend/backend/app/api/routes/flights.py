from typing import Any, Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select

from app import crud
from app.api.deps import CurrentStaffUser, SessionDep
from app.models import (
    Flight,
    FlightCreate,
    FlightPublic,
    FlightsPublic,
    FlightUpdate,
    FlightStatusUpdate,
    FlightGateTerminalUpdate,
    FlightSeat,
    FlightSearchResult,
    FlightSeatStatus
)

router = APIRouter(prefix="/flights", tags=["flights"])


# =====================
# CREATE FLIGHT (STAFF ONLY)
# =====================
@router.post(
    "",
    response_model=FlightPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def create_flight(
    *,
    session: SessionDep,
    flight_in: FlightCreate,
) -> Any:
    if flight_in.arrival_time <= flight_in.departure_time:
        raise HTTPException(
            status_code=400,
            detail="Arrival time must be after departure time",
        )

    created_flight = crud.create_flight(session=session, flight_in=flight_in)
    
    # Convert Flight to FlightPublic with airport codes
    flight_dict = created_flight.model_dump()
    flight_dict['origin_airport_code'] = created_flight.origin_airport.code if created_flight.origin_airport else None
    flight_dict['destination_airport_code'] = created_flight.destination_airport.code if created_flight.destination_airport else None
    return FlightPublic(**flight_dict)


# =====================
# READ ALL FLIGHTS (PUBLIC)
# =====================
@router.get("", response_model=FlightsPublic)
def read_flights(
    *,
    session: SessionDep,
    skip: int = 0,
    limit: int = 100,
) -> Any:
    flights = crud.get_flights(session=session, skip=skip, limit=limit)
    count = len(flights)
    
    # Convert Flight to FlightPublic with airport codes
    flight_publics = []
    for flight in flights:
        flight_dict = flight.model_dump()
        flight_dict['origin_airport_code'] = flight.origin_airport.code if flight.origin_airport else None
        flight_dict['destination_airport_code'] = flight.destination_airport.code if flight.destination_airport else None
        flight_publics.append(FlightPublic(**flight_dict))
    
    return FlightsPublic(data=flight_publics, count=count)


# =====================
# READ ONE FLIGHT (PUBLIC)
# =====================
@router.get("/{flight_id}", response_model=FlightPublic)
def read_flight(
    *,
    session: SessionDep,
    flight_id: str,
) -> Any:
    flight = crud.get_flight(session=session, flight_id=flight_id)
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    
    # Convert Flight to FlightPublic with airport codes
    flight_dict = flight.model_dump()
    flight_dict['origin_airport_code'] = flight.origin_airport.code if flight.origin_airport else None
    flight_dict['destination_airport_code'] = flight.destination_airport.code if flight.destination_airport else None
    return FlightPublic(**flight_dict)


# =====================
# UPDATE FLIGHT (STAFF ONLY)
# =====================
@router.put(
    "/{flight_id}",
    response_model=FlightPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_flight(
    *,
    session: SessionDep,
    flight_id: str,
    flight_in: FlightUpdate,
) -> Any:
    db_flight = crud.get_flight(session=session, flight_id=flight_id)
    if not db_flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    if (
        flight_in.departure_time
        and flight_in.arrival_time
        and flight_in.arrival_time <= flight_in.departure_time
    ):
        raise HTTPException(
            status_code=400,
            detail="Arrival time must be after departure time",
        )

    updated_flight = crud.update_flight(
        session=session,
        db_flight=db_flight,
        flight_in=flight_in,
    )
    
    # Convert Flight to FlightPublic with airport codes
    flight_dict = updated_flight.model_dump()
    flight_dict['origin_airport_code'] = updated_flight.origin_airport.code if updated_flight.origin_airport else None
    flight_dict['destination_airport_code'] = updated_flight.destination_airport.code if updated_flight.destination_airport else None
    return FlightPublic(**flight_dict)


# =====================
# DELETE FLIGHT (STAFF ONLY)
# =====================
@router.delete(
    "/{flight_id}",
    dependencies=[Depends(CurrentStaffUser)],
)
def delete_flight(
    *,
    session: SessionDep,
    flight_id: str,
) -> Any:
    db_flight = crud.get_flight(session=session, flight_id=flight_id)
    if not db_flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    crud.delete_flight(session=session, db_flight=db_flight)
    return {"ok": True}


# =====================
# UPDATE FLIGHT STATUS (STAFF ONLY)
# =====================
@router.patch(
    "/{flight_id}/status",
    response_model=FlightPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_flight_status(
    *,
    session: SessionDep,
    flight_id: str,
    payload: FlightStatusUpdate,
) -> Any:
    print(f"[API] PATCH /flights/{flight_id}/status - New status: {payload.status}")
    db_flight = crud.get_flight(session=session, flight_id=flight_id)
    if not db_flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    updated_flight = crud.update_flight(
        session=session,
        db_flight=db_flight,
        flight_in=payload,
    )
    print(f"[API] Successfully updated flight status for flight_id={flight_id}")
    
    # Convert Flight to FlightPublic with airport codes
    flight_dict = updated_flight.model_dump()
    flight_dict['origin_airport_code'] = updated_flight.origin_airport.code if updated_flight.origin_airport else None
    flight_dict['destination_airport_code'] = updated_flight.destination_airport.code if updated_flight.destination_airport else None
    return FlightPublic(**flight_dict)


# =====================
# UPDATE GATE / TERMINAL (STAFF ONLY)
# =====================
@router.patch(
    "/{flight_id}/gate-terminal",
    response_model=FlightPublic,
    dependencies=[Depends(CurrentStaffUser)],
)
def update_gate_terminal(
    *,
    session: SessionDep,
    flight_id: str,
    payload: FlightGateTerminalUpdate,
) -> Any:
    db_flight = crud.get_flight(session=session, flight_id=flight_id)
    if not db_flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    updated_flight = crud.update_flight(
        session=session,
        db_flight=db_flight,
        flight_in=payload,
    )
    
    # Convert Flight to FlightPublic with airport codes
    flight_dict = updated_flight.model_dump()
    flight_dict['origin_airport_code'] = updated_flight.origin_airport.code if updated_flight.origin_airport else None
    flight_dict['destination_airport_code'] = updated_flight.destination_airport.code if updated_flight.destination_airport else None
    return FlightPublic(**flight_dict)


# =====================
# SEARCH FLIGHTS (PASSENGER)
# =====================

@router.get("/{flight_id}/seat-map")
def get_seat_map(
    *,
    session: SessionDep,
    flight_id: str,
) -> Any:
    flight = crud.get_flight(session=session, flight_id=flight_id)
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")

    seats = session.exec(
        select(FlightSeat)
        .where(FlightSeat.flight_id == flight_id)
        .order_by(FlightSeat.row, FlightSeat.seat_label)
    ).all()

    return {
        "flight_id": flight.id,
        "flight_number": flight.flight_number,
        "seats": seats,
    }


@router.get("/search", response_model=list[FlightSearchResult])
def search_flights(
    *,
    session: SessionDep,
    origin_airport_id: str,
    destination_airport_id: str,
    departure_date_from: date,
    departure_date_to: Optional[date] = None,
) -> Any:
    print(f"Flights API: Search request received:")
    print(f"  - Origin Airport ID: {origin_airport_id}")
    print(f"  - Destination Airport ID: {destination_airport_id}")
    print(f"  - Departure Date From: {departure_date_from}")
    print(f"  - Departure Date To: {departure_date_to}")
    
    flights = crud.search_flights(
        session=session,
        origin_airport_id=origin_airport_id,
        destination_airport_id=destination_airport_id,
        departure_date_from=departure_date_from,
        departure_date_to=departure_date_to,
    )
    
    print(f"Flights API: Found {len(flights)} flights matching criteria")

    results: list[FlightSearchResult] = []

    for flight in flights:
        seats = flight.seats or []

        available_seats = [
            s for s in seats if s.status == FlightSeatStatus.AVAILABLE
        ]

        prices = [s.price for s in available_seats]

        duration_minutes = int(
            (flight.arrival_time - flight.departure_time).total_seconds() / 60
        )

        results.append(
            FlightSearchResult(
                flight_id=flight.id,
                flight_number=flight.flight_number,
                origin_airport_code=flight.origin_airport.code,
                destination_airport_code=flight.destination_airport.code,
                departure_time=flight.departure_time,
                arrival_time=flight.arrival_time,
                duration_minutes=duration_minutes,
                price_from=min(prices) if prices else 0,
                available_seats=len(available_seats),
                status=flight.status,
            )
        )

    return results
