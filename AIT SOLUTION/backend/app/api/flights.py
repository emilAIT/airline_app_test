from fastapi import APIRouter, Depends, Query, HTTPException, Body
from sqlmodel import Session
from typing import List, Optional
from pydantic import BaseModel
from app.database import get_session
from app.models import Flight, User
from app.core.deps import get_current_user
from app.services.all_services import FlightService

router = APIRouter(prefix="/flights", tags=["flights"])

@router.get("/")
# Назначение: Поиск рейсов с фильтрами по направлениям, дате и количеству пассажиров
# Принимает: departure, arrival, date, passengers_count
# Возвращает: список рейсов с доступными местами
def list_flights(
    departure: Optional[str] = None,
    arrival: Optional[str] = None,
    date: Optional[str] = None,
    passengers_count: Optional[int] = Query(default=None, ge=1),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.get_all_flights(
        user=current_user,
        departure=departure,
        arrival=arrival,
        date=date,
        passengers_count=passengers_count
    )

@router.post("/")
# Назначение: Создание рейса со всеми обязательными gate полями
# Принимает: словарь данных рейса
# Возвращает: созданный рейс
def create_flight(
    data: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.create_flight(data, current_user)

@router.get("/{flight_id}/seats")
# Назначение: Получить актуальную схему мест по рейсу
# Принимает: flight_id
# Возвращает: список мест с признаком доступности и классом
def get_flight_seats(
    flight_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.get_flight_seat_map(flight_id)

@router.patch("/{flight_id}/status", response_model=Flight)
# Назначение: Обновить статус рейса с уведомлением всех пассажиров
# Принимает: flight_id, новый статус в теле запроса {"status": "scheduled"}
# Возвращает: рейс после обновления
def update_flight_status(
    flight_id: int,
    body: dict = Body(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    status = body.get("status")
    if not status:
        raise HTTPException(status_code=422, detail="Status field is required in request body")
    service = FlightService(session)
    return service.update_flight_status(flight_id, status, current_user)

@router.patch("/{flight_id}/gate")
# Назначение: Обновление gate вылета и прилета с уведомлением пассажиров
# Принимает: flight_id и новые значения gate
# Возвращает: рейс после обновления
def update_flight_gates(
    flight_id: int,
    data: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.update_flight_gates(
        flight_id=flight_id,
        gate_departure=data.get("gate_departure"),
        gate_arrival=data.get("gate_arrival"),
        user=current_user
    )

@router.get("/{flight_id}/passengers")
# Назначение: Получить список всех пассажиров рейса (staff only)
# Принимает: flight_id
# Возвращает: список пассажиров с информацией о местах
def get_flight_passengers(
    flight_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.get_flight_passengers(flight_id, current_user)

@router.get("/passengers/summary")
# Назначение: Получить сводку по пассажирам всех рейсов (staff only)
# Принимает: нет
# Возвращает: сводку по всем рейсам
def get_all_flights_passengers_summary(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = FlightService(session)
    return service.get_all_flights_passengers_summary(current_user)
