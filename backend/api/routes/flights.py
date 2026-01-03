from datetime import date, datetime, time
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import aliased, Session
from typing import List

from db.session import get_db
from core.dependencies import require_passenger
from models.airport import Airport
from models.flight import Flight
from models.seat_hold import SeatHold
from models.user import User
from schemas.flight import (
    # FlightCreate,
    # FlightResponse,
    # FlightScheduleUpdate,
    # FlightAssignAirplane,
    # FlightGateUpdate,
    # FlightTerminalUpdate,
    # FlightStatusUpdate,
    FlightOut
)

from core.dependencies import require_staff

router = APIRouter(
    prefix="/flights",
    tags=["Flights"]
)

OriginAirport = aliased(Airport)
DestinationAirport = aliased(Airport)

@router.get("/search", response_model=List[FlightOut])
def search_flights(
    origin_code: str,
    destination_code: str,
    departure_date: date,
    db: Session = Depends(get_db),
):
    departure_datetime = datetime.combine(departure_date, time.min)

    flights = Flight.search(
        db=db,
        origin_code=origin_code,
        destination_code=destination_code,
        departure_date=departure_datetime
    )

    if not flights:
        return []

    return flights

from pydantic import BaseModel

class HoldSeatsSchema(BaseModel):
    seats: List[str]

@router.get("/{flight_id}/seat-map")
def seat_map(
    flight_id: int,
    db: Session = Depends(get_db)
):
    flight = db.query(Flight).get(flight_id)
    if not flight:
        raise HTTPException(404, "Flight not found")
    
    if not flight.airplane or not flight.airplane.seat_map_templates:
        raise HTTPException(400, "Flight has no airplane or seat map assigned")

    template = flight.airplane.seat_map_templates[0]
    seat_map = template.get_seat_map()

    now = datetime.utcnow()

    booked = {
        t.seat_number
        for t in flight.tickets
    }

    held = {
        h.seat_number
        for h in db.query(SeatHold)
        .filter(
            SeatHold.flight_id == flight_id,
            SeatHold.expires_at > now
        )
    }

    for seat in seat_map:
        seat["seat_number"] = seat["label"]  # Align with frontend
        if seat["label"] in booked:
            seat["status"] = "OCCUPIED"  # App expects OCCUPIED
        elif seat["label"] in held:
            seat["status"] = "HELD"
        else:
            seat["status"] = "AVAILABLE"

    return seat_map

@router.post("/{flight_id}/hold-seats/")
def hold_seats(
    flight_id: int,
    data: HoldSeatsSchema,
    db: Session = Depends(get_db),
    user: User = Depends(require_passenger)
):
    now = datetime.utcnow()
    seats = data.seats

    # очистка протухших
    db.query(SeatHold).filter(
        SeatHold.expires_at < now
    ).delete()

    for seat in seats:
        exists = db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.seat_number == seat,
            SeatHold.expires_at > now
        ).first()
        if exists:
            raise HTTPException(400, f"Seat {seat} is already held")

        db.add(
            SeatHold(
                flight_id=flight_id,
                seat_number=seat,
                user_id=user.id,
                expires_at=SeatHold.hold_for_10_minutes()
            )
        )

    db.commit()
    return {"status": "held"}

@router.get("/{flight_id}/seats")
def get_flight_seats(
    flight_id: int,
    db: Session = Depends(get_db)
):
    flight = db.query(Flight).get(flight_id)

    seat_template = flight.airplane.seat_map_templates[0]
    all_seats = seat_template.get_seat_map()

    booked = {
        t.seat_number for t in flight.tickets
    }

    for seat in all_seats:
        seat["available"] = seat["label"] not in booked

    return all_seats



# ------------------ GET ALL FLIGHTS ------------------
@router.get("/", response_model=List[FlightOut])
def get_all_flights(db: Session = Depends(get_db)):
    return db.query(Flight).all()

# # ------------------ GET SINGLE FLIGHT ------------------
# @router.get("/{flight_id}", response_model=FlightOut)
# def get_flight(flight_id: int, db: Session = Depends(get_db)):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     return flight


# # ------------------ CREATE FLIGHT ------------------
# @router.post("/", response_model=FlightResponse, status_code=status.HTTP_201_CREATED)
# def create_flight(
#     data: FlightCreate,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     return Flight.create_flight(
#         db=db,
#         flight_number=data.flight_number,
#         origin_code=data.origin_code,
#         destination_code=data.destination_code,
#         departure_time=data.departure_time,
#         arrival_time=data.arrival_time,
#         price=data.price
#     )


# # ------------------ ASSIGN AIRPLANE ------------------
# @router.put("/{flight_id}/assign-airplane", response_model=FlightResponse)
# def assign_airplane(
#     flight_id: int,
#     data: FlightAssignAirplane,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     return flight.assign_airplane(db, data.airplane_id)


# # ------------------ UPDATE SCHEDULE ------------------
# @router.put("/{flight_id}/schedule", response_model=FlightResponse)
# def update_schedule(
#     flight_id: int,
#     data: FlightScheduleUpdate,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     return flight.update_schedule(
#         db,
#         departure_time=data.departure_time,
#         arrival_time=data.arrival_time
#     )


# # ------------------ UPDATE GATE ------------------
# @router.put("/{flight_id}/gate", response_model=FlightResponse)
# def update_gate(
#     flight_id: int,
#     data: FlightGateUpdate,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     return flight.update_gate(db, data.gate)


# # ------------------ UPDATE TERMINAL ------------------
# @router.put("/{flight_id}/terminal", response_model=FlightResponse)
# def update_terminal(
#     flight_id: int,
#     data: FlightTerminalUpdate,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     return flight.update_terminal(db, data.terminal)


# # ------------------ UPDATE STATUS ------------------
# @router.put("/{flight_id}/status", response_model=FlightResponse)
# def update_status(
#     flight_id: int,
#     data: FlightStatusUpdate,
#     db: Session = Depends(get_db),
#     _: User = Depends(require_staff)
# ):
#     flight = db.query(Flight).filter(Flight.id == flight_id).first()
#     if not flight:
#         raise HTTPException(status_code=404, detail="Flight not found")
#     try:
#         return flight.update_status(db, data.status)
#     except ValueError as e:
#         raise HTTPException(status_code=400, detail=str(e))
