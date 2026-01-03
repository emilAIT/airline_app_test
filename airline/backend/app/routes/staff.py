from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session, selectinload
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_staff
from app.models.user import User, UserRole
from app.models.airport import Airport as AirportModel
from app.models.flight import Flight as FlightModel, FlightStatus
from app.models.aircraft import Aircraft as AircraftModel
from app.models.booking import Booking as BookingModel, BookingStatus
from app.models.announcement import Announcement as AnnouncementModel

from app.schemas.airport import Airport, AirportCreate, AirportDetail
from app.schemas.aircraft import Aircraft, AircraftCreate, SeatTemplate, SeatTemplateCreate, AircraftDetail
from app.schemas.flight import Flight, FlightCreate, FlightUpdate
from app.schemas.booking import Booking, SeatConflict
from app.schemas.announcement import Announcement, AnnouncementCreate
from app.schemas.seat import StaffSeatMap
from app.schemas.payment import StaffPayment
from app.schemas.user import UserProfile
from app.models.payment import Payment as PaymentModel, TransactionStatus
from sqlalchemy.orm import joinedload
from typing import Optional

from app.services.aircraft_service import (
    create_seat_template,
    get_seat_templates,
    delete_seat_template,
    create_aircraft,
    get_aircrafts,
    delete_aircraft
)
from app.services.flight_service import (
    get_airports,
    get_flight_by_id,
    create_flight,
    update_flight,
    delete_flight,
    delete_airport,
    get_staff_flight_seat_map,
    get_flight_seat_map
)
from app.services.announcement_service import create_announcement, get_flight_announcements, delete_announcement
from app.services.booking_service import staff_cancel_booking, staff_block_seat, staff_reassign_seat

router = APIRouter(prefix="/staff", tags=["Staff"])


# ===================== АЭРОПОРТЫ =====================

@router.get("/airports", response_model=List[Airport], tags=["Staff - Airports"])
def list_airports(db: Session = Depends(get_db)):
    """Список аэропортов"""
    return get_airports(db)


@router.post("/airports", response_model=Airport, status_code=status.HTTP_201_CREATED, tags=["Staff - Airports"])
def create_airport(airport_data: AirportCreate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Создать аэропорт"""
    if db.query(AirportModel).filter(AirportModel.code == airport_data.code).first():
        raise HTTPException(status_code=400, detail="Аэропорт с таким кодом уже существует")
    airport = AirportModel(**airport_data.dict())
    db.add(airport)
    db.commit()
    db.refresh(airport)
    return airport


@router.get("/airports/{airport_id}", response_model=AirportDetail, tags=["Staff - Airports"])
def get_airport_detail(airport_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Детали аэропорта"""
    airport = db.query(AirportModel).options(
        selectinload(AirportModel.origin_flights).selectinload(FlightModel.destination_airport),
        selectinload(AirportModel.destination_flights).selectinload(FlightModel.origin_airport)
    ).filter(AirportModel.id == airport_id).first()
    if not airport: raise HTTPException(status_code=404, detail="Аэропорт не найден")
    return airport


# ===================== САМОЛЁТЫ / ШАБЛОНЫ =====================

@router.post("/seat-templates", response_model=SeatTemplate, status_code=status.HTTP_201_CREATED)
def create_seat_template_endpoint(template_data: SeatTemplateCreate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return create_seat_template(db, template_data)


@router.get("/seat-templates", response_model=List[SeatTemplate])
def list_seat_templates(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return get_seat_templates(db)


@router.delete("/seat-templates/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_seat_template_endpoint(template_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    delete_seat_template(db, template_id)
    return None


@router.post("/aircrafts", response_model=Aircraft, status_code=status.HTTP_201_CREATED, tags=["Staff - Aircrafts"])
def create_aircraft_endpoint(aircraft_data: AircraftCreate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return create_aircraft(db, aircraft_data)


@router.get("/aircrafts", response_model=List[Aircraft], tags=["Staff - Aircrafts"])
def list_aircrafts(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return get_aircrafts(db)


@router.delete("/aircrafts/{aircraft_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Staff - Aircrafts"])
def delete_aircraft_endpoint(aircraft_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    delete_aircraft(db, aircraft_id)
    return None


@router.get("/aircrafts/{aircraft_id}", response_model=AircraftDetail, tags=["Staff - Aircrafts"])
def get_aircraft_detail(aircraft_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    aircraft = db.query(AircraftModel).options(
        selectinload(AircraftModel.flights).selectinload(FlightModel.origin_airport),
        selectinload(AircraftModel.flights).selectinload(FlightModel.destination_airport)
    ).filter(AircraftModel.id == aircraft_id).first()
    if not aircraft: raise HTTPException(status_code=404, detail="Самолёт не найден")
    return aircraft


# ===================== РЕЙСЫ =====================

def _list_flights_by_status(db: Session, statuses: List[FlightStatus]):
    from app.services.flight_service import update_flight_statuses
    update_flight_statuses(db)
    return db.query(FlightModel).options(
        joinedload(FlightModel.origin_airport),
        joinedload(FlightModel.destination_airport)
    ).filter(FlightModel.status.in_(statuses)).order_by(FlightModel.scheduled_departure.asc()).all()


@router.get("/flights/upcoming", response_model=List[Flight], tags=["Staff - Flights: Upcoming & Active"])
def list_upcoming_flights(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Рейсы: По расписанию, Задержан, Посадка"""
    return _list_flights_by_status(db, [FlightStatus.SCHEDULED, FlightStatus.DELAYED, FlightStatus.BOARDING])


@router.get("/flights/active", response_model=List[Flight], tags=["Staff - Flights: In Air"])
def list_active_flights(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Рейсы: В полете (Вылетел)"""
    return _list_flights_by_status(db, [FlightStatus.DEPARTED])


@router.get("/flights/past", response_model=List[Flight], tags=["Staff - Flights: Archive"])
def list_past_flights(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Рейсы: Прибыл, Отменен"""
    return _list_flights_by_status(db, [FlightStatus.ARRIVED, FlightStatus.CANCELLED])


@router.post("/flights", response_model=Flight, status_code=status.HTTP_201_CREATED, tags=["Staff - Flights: Management"])
def create_flight_endpoint(flight_data: FlightCreate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Создать рейс"""
    return create_flight(db, flight_data)


@router.get("/flights", response_model=List[Flight], tags=["Staff - Flights: Management"])
def list_flights_all(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Полный список всех рейсов для управления"""
    from app.services.flight_service import update_flight_statuses
    update_flight_statuses(db)
    return db.query(FlightModel).all()


@router.get("/flights/{flight_id}", response_model=Flight, tags=["Staff - Flights: Management"])
def get_flight(flight_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Детали конкретного рейса"""
    return get_flight_by_id(db, flight_id)


@router.put("/flights/{flight_id}", response_model=Flight, tags=["Staff - Flights: Management"])
def update_flight_endpoint(flight_id: int, flight_data: FlightUpdate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Изменить параметры рейса (время, статус, гейт)"""
    return update_flight(db, flight_id, flight_data)


@router.delete("/flights/{flight_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Staff - Flights: Management"])
def delete_flight_endpoint(flight_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Удалить рейс из системы"""
    delete_flight(db, flight_id)
    return None


@router.get("/flights/{flight_id}/seats", response_model=StaffSeatMap, tags=["Staff - Flights: Management"])
def get_flight_seats_staff(flight_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Карта мест рейса с именами пассажиров (админ)"""
    return get_staff_flight_seat_map(db, flight_id)


# ===================== БРОНИРОВАНИЯ =====================

@router.get("/bookings", response_model=List[Booking], tags=["Staff - Bookings: Generic"])
def list_bookings(
    flight_id: Optional[int] = None, 
    pnr: Optional[str] = None,
    current_user: User = Depends(get_current_staff), 
    db: Session = Depends(get_db)
):
    """Общий список всех бронирований (для совместимости с фронтендом)"""
    query = db.query(BookingModel).options(
        joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport),
        joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport),
        joinedload(BookingModel.ticket)
    )
    
    if flight_id:
        query = query.filter(BookingModel.flight_id == flight_id)
    if pnr:
        query = query.filter(BookingModel.pnr == pnr)
        
    bookings = query.order_by(BookingModel.created_at.desc()).all()
    return [Booking.model_validate(b) for b in bookings]


def _list_bookings_by_status(db: Session, status: BookingStatus, flight_id: Optional[int] = None, pnr: Optional[str] = None):
    query = db.query(BookingModel).options(
        joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport),
        joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport),
        joinedload(BookingModel.ticket)
    ).filter(BookingModel.status == status)
    
    if flight_id:
        query = query.filter(BookingModel.flight_id == flight_id)
    if pnr:
        query = query.filter(BookingModel.pnr == pnr)
        
    bookings = query.order_by(BookingModel.created_at.desc()).all()
    return [Booking.model_validate(b) for b in bookings]


@router.get("/bookings/confirmed", response_model=List[Booking], tags=["Staff - Bookings: Confirmed"])
def list_confirmed_bookings(flight_id: Optional[int] = None, pnr: Optional[str] = None, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Список всех оплаченных и подтвержденных бронирований"""
    return _list_bookings_by_status(db, BookingStatus.CONFIRMED, flight_id, pnr)


@router.get("/bookings/pending", response_model=List[Booking], tags=["Staff - Bookings: Pending/Created"])
def list_pending_bookings(flight_id: Optional[int] = None, pnr: Optional[str] = None, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Список временных бронирований (ожидают оплаты 10 мин)"""
    return _list_bookings_by_status(db, BookingStatus.CREATED, flight_id, pnr)


@router.get("/bookings/cancelled", response_model=List[Booking], tags=["Staff - Bookings: Cancelled"])
def list_cancelled_bookings(flight_id: Optional[int] = None, pnr: Optional[str] = None, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Список отмененных бронирований"""
    return _list_bookings_by_status(db, BookingStatus.CANCELLED, flight_id, pnr)


@router.get("/bookings/{booking_id}", response_model=Booking, tags=["Staff - Bookings: Generic"])
def get_booking(booking_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Детальная информация о конкретном бронировании"""
    booking = db.query(BookingModel).options(
        joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport),
        joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport),
        joinedload(BookingModel.ticket)
    ).filter(BookingModel.id == booking_id).first()
    if not booking: raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return Booking.model_validate(booking)


class SeatReassignRequest(BaseModel):
    new_seat_number: str

@router.post("/bookings/{booking_id}/reassign", response_model=Booking, tags=["Staff - Bookings: Operations"])
def reassign_seat_endpoint(booking_id: int, request: SeatReassignRequest, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Переназначить место пассажира (с уведомлением в историю)"""
    return staff_reassign_seat(db, booking_id, request.new_seat_number)


@router.post("/bookings/{booking_id}/cancel", response_model=Booking, tags=["Staff - Bookings: Operations"])
def cancel_booking_endpoint(booking_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Отменить бронирование администратором"""
    return staff_cancel_booking(db, booking_id)


class SeatBlockRequest(BaseModel):
    seat_number: str

@router.post("/flights/{flight_id}/block-seat", response_model=Booking, tags=["Staff - Bookings: Operations"])
def block_seat_endpoint(flight_id: int, request: SeatBlockRequest, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Заблокировать место (системная блокировка)"""
    return staff_block_seat(db, flight_id, request.seat_number, current_user.id)


@router.get("/flights/{flight_id}/conflicts", response_model=List[SeatConflict], tags=["Staff - Bookings: Operations"])
def get_seat_conflicts(flight_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Найти конфликты мест на рейсе"""
    bookings = db.query(BookingModel).filter(
        BookingModel.flight_id == flight_id,
        BookingModel.status == BookingStatus.CONFIRMED
    ).options(joinedload(BookingModel.ticket)).all()
    
    seat_groups = {}
    for b in bookings:
        if b.seat_number not in seat_groups:
            seat_groups[b.seat_number] = []
        seat_groups[b.seat_number].append(b)
        
    conflicts = []
    for seat, group in seat_groups.items():
        if len(group) > 1:
            conflicts.append({
                "seat_number": seat,
                "bookings": [Booking.model_validate(b) for b in group]
            })
    return conflicts


# ===================== ОБЪЯВЛЕНИЯ =====================

@router.post("/announcements", response_model=Announcement, status_code=status.HTTP_201_CREATED, tags=["Staff - Announcements"])
def create_announcement_endpoint(announcement_data: AnnouncementCreate, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return Announcement.model_validate(create_announcement(db, announcement_data, current_user.id))


@router.get("/flights/{flight_id}/announcements", response_model=List[Announcement], tags=["Staff - Announcements"])
def get_flight_announcements_endpoint(flight_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    return get_flight_announcements(db, flight_id)


@router.delete("/announcements/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Staff - Announcements"])
def delete_announcement_endpoint(announcement_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    delete_announcement(db, announcement_id)
    return None


@router.get("/announcements", response_model=List[Announcement], tags=["Staff - Announcements"])
def list_all_announcements(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    announcements = db.query(AnnouncementModel).order_by(AnnouncementModel.created_at.desc()).all()
    return [Announcement.model_validate(a) for a in announcements]


# ===================== ПОЛЬЗОВАТЕЛИ =====================

@router.get("/users", response_model=List[UserProfile], tags=["Staff - Users"])
def list_all_users(current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Список всех зарегистрированных пользователей"""
    return db.query(User).all()


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Staff - Users"])
def delete_user(user_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Удалить пассажира (запрещено удалять сотрудников)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user: raise HTTPException(status_code=404, detail="Пользователь не найден")
    if user.id == current_user.id: raise HTTPException(status_code=400, detail="Нельзя удалить самого себя")
    
    # Restriction: Only passengers can be deleted by staff
    if user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403, 
            detail="Ошибка доступа: сотрудники и администраторы не могут быть удалены через этот интерфейс."
        )
        
    db.delete(user)
    db.commit()


@router.post("/users/{user_id}/block", response_model=UserProfile, summary="Заблокировать/Разблокировать пассажира", tags=["Staff - Users"])
def toggle_block_user(user_id: int, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Переключает статус активности аккаунта пассажира"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user: raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    if user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403, 
            detail="Ошибка доступа: статус сотрудников и администраторов изменять нельзя."
        )
        
    user.is_active = not user.is_active
    db.commit()
    db.refresh(user)
    return user
# ===================== ПЛАТЕЖИ =====================

@router.get("/payments", response_model=List[StaffPayment], tags=["Staff - Payments"])
def list_payments(status: Optional[TransactionStatus] = None, current_user: User = Depends(get_current_staff), db: Session = Depends(get_db)):
    """Список всех платежей"""
    query = db.query(PaymentModel).options(
        joinedload(PaymentModel.booking).joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport),
        joinedload(PaymentModel.booking).joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport),
        joinedload(PaymentModel.passenger)
    )
    
    if status:
        query = query.filter(PaymentModel.status == status)
        
    payments = query.order_by(PaymentModel.created_at.desc()).all()
    
    # Process for response
    result = []
    for p in payments:
        result.append({
            "id": p.id,
            "transaction_id": p.transaction_id,
            "booking_id": p.booking_id,
            "passenger_id": p.passenger_id,
            "passenger_name": p.passenger.full_name if p.passenger else "Unknown",
            "amount": p.amount,
            "currency": p.currency,
            "method": p.method,
            "status": p.status,
            "created_at": p.created_at,
            "pnr": p.pnr,
            "flight_info": p.flight_info
        })
    return result
