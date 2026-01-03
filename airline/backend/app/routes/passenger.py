from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_
from pydantic import BaseModel

from app.core.database import get_db
from app.core.dependencies import get_current_passenger
from app.models.user import User, UserRole
from app.models.flight import Flight as FlightModel, FlightStatus
from app.models.announcement import Announcement as AnnouncementModel
from app.models.booking import Booking as BookingModel, BookingStatus, SeatHold as SeatHoldModel
from app.schemas.booking import (
    Booking
)
from app.schemas.seat import SeatMap, BookWithPassengersRequest, BookSeatsResponse, SeatHoldRequest, SeatHoldResponse
from app.schemas.user import UserProfile
from app.schemas.flight import Flight, FlightDetail, FlightSearch, Trip, CheckInRequest, CheckInResponse
from app.schemas.airport import Airport
from app.schemas.announcement import Announcement
from app.schemas.payment import PaymentTransaction, PaymentItem
from app.models.payment import Payment as PaymentModel

from app.services.flight_service import get_flight_by_id, get_flight_seat_map, search_flights as search_flights_service
from app.services.booking_service import hold_seats as hold_seats_service, create_bookings_with_passengers, check_in as check_in_service

router = APIRouter(prefix="/passenger", tags=["Passenger"])


def _filter_flights(db: Session, from_city: Optional[str], to_city: Optional[str], date: Optional[str]) -> List[FlightModel]:
    """Вспомогательная функция для фильтрации рейсов"""
    now = datetime.utcnow()
    booking_cutoff = now + timedelta(hours=2)
    
    query = db.query(FlightModel).options(joinedload(FlightModel.aircraft)).filter(
        FlightModel.scheduled_departure >= booking_cutoff,
        FlightModel.status != FlightStatus.CANCELLED
    )
    
    if date:
        try:
            target_datetime = datetime.fromisoformat(date.replace('Z', '+00:00')) if 'T' in date else datetime.strptime(date, "%Y-%m-%d")
            start_date = target_datetime.replace(hour=0, minute=0, second=0)
            query = query.filter(FlightModel.scheduled_departure >= start_date, FlightModel.scheduled_departure < start_date + timedelta(days=1))
        except (ValueError, TypeError):
            pass

    flights = query.all()
    if from_city:
        flights = [f for f in flights if f.departure_city.lower() == from_city.lower().strip()]
    if to_city:
        flights = [f for f in flights if f.arrival_city.lower() == to_city.lower().strip()]
    return flights


# ===================== PUBLIC ENDPOINTS =====================

@router.get("/flights/public", response_model=List[Flight], tags=["Passenger - Search & Flights"])
def get_flights_public(from_city: str = None, to_city: str = None, date: str = None, db: Session = Depends(get_db)):
    """Публичный список рейсов (доступен без логина)"""
    return [Flight.model_validate(f) for f in _filter_flights(db, from_city, to_city, date)]


@router.get("/public/flight/{flight_id}", response_model=Flight, tags=["Passenger - Search & Flights"])
def get_flight_details_public(flight_id: int, db: Session = Depends(get_db)):
    """Публичные детали рейса"""
    return Flight.model_validate(get_flight_by_id(db, flight_id))


@router.get("/airports", response_model=List[Airport], tags=["Passenger - Search & Flights"])
def get_airports(db: Session = Depends(get_db)):
    """Публичный список аэропортов"""
    from app.models.airport import Airport as AirportModel
    return [Airport.model_validate(a) for a in db.query(AirportModel).all()]


# ===================== PROTECTED ENDPOINTS =====================

@router.get("/flights", response_model=List[Flight], tags=["Passenger - Search & Flights"])
def get_flights(from_city: str = None, to_city: str = None, date: str = None, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Список рейсов для авторизованных пользователей"""
    return [Flight.model_validate(f) for f in _filter_flights(db, from_city, to_city, date)]


@router.get("/flights/{flight_id}", response_model=FlightDetail, tags=["Passenger - Search & Flights"])
def get_flight_details(flight_id: int, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Детали рейса (защищенный)"""
    return FlightDetail.model_validate(get_flight_by_id(db, flight_id))


@router.get("/flights/{flight_id}/seats", response_model=SeatMap, tags=["Passenger - Booking Flow"])
def get_flight_seats(flight_id: int, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Карта мест (выбор мест)"""
    return get_flight_seat_map(db, flight_id)


@router.post("/flights/{flight_id}/hold-seats", response_model=SeatHoldResponse, tags=["Passenger - Booking Flow"])
def hold_seats(flight_id: int, request: SeatHoldRequest, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Зарезервировать места (на 10 минут)"""
    return hold_seats_service(db, flight_id, request, current_user.id)


@router.post("/flights/{flight_id}/book-with-passengers", response_model=BookSeatsResponse, tags=["Passenger - Booking Flow"])
def book_seats_with_passengers(flight_id: int, request: BookWithPassengersRequest, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Подтвердить бронирование с данными пассажиров"""
    return create_bookings_with_passengers(db, flight_id, request, current_user.id)


@router.get("/profile/trips", response_model=List[Trip], tags=["Passenger - My Trips & Tickets"])
def get_my_trips(current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Список моих поездок (включая попутчиков)"""
    from sqlalchemy import or_, and_
    from app.models.payment import Payment as PaymentModel
    
    # 1. Находим все бронирования, где пользователь либо плательщик, либо пассажир
    user_bookings_query = db.query(BookingModel).filter(
        or_(
            BookingModel.passenger_id == current_user.id,
            and_(BookingModel.passport_number == current_user.passport_number, BookingModel.passport_number != None)
        )
    )
    user_bookings = user_bookings_query.all()
    user_booking_ids = [b.id for b in user_bookings]
    
    # 2. Собираем все PNR и Transaction ID этих бронирований
    my_pnrs = {b.pnr for b in user_bookings if b.pnr}
    
    # Ищем transaction_ids через таблицу Payment
    transaction_ids = set()
    if user_booking_ids:
        tx_query = db.query(PaymentModel.transaction_id).filter(PaymentModel.booking_id.in_(user_booking_ids)).all()
        transaction_ids = {tx[0] for tx in tx_query if tx[0]}
    
    # 3. Находим ВСЕ бронирования, которые делят хотя бы один PNR или Transaction ID
    # А также все черновики пользователя (без PNR)
    
    # Для поиска по транзакциям нам сначала нужны ID всех связанных бронирований
    linked_by_tx_ids = set()
    if transaction_ids:
        linked_tx_query = db.query(PaymentModel.booking_id).filter(PaymentModel.transaction_id.in_(list(transaction_ids))).all()
        linked_by_tx_ids = {l[0] for l in linked_tx_query}
        
    final_bookings = db.query(BookingModel).options(
        joinedload(BookingModel.flight).joinedload(FlightModel.aircraft),
        joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport),
        joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport),
        joinedload(BookingModel.ticket),
        joinedload(BookingModel.payment)
    ).filter(
        or_(
            BookingModel.pnr.in_(list(my_pnrs)) if my_pnrs else False,
            BookingModel.id.in_(list(linked_by_tx_ids)) if linked_by_tx_ids else False,
            BookingModel.passenger_id == current_user.id,  # Include all bookings purchased by user
            and_(BookingModel.passport_number == current_user.passport_number, BookingModel.passport_number != None) # Also by traveler identity
        )
    ).all()
    
    now = datetime.utcnow()
    holds = db.query(SeatHoldModel).filter(SeatHoldModel.passenger_id == current_user.id, SeatHoldModel.expires_at > now).all()
    active_holds = { (h.flight_id, h.seat_number): h for h in holds }
    
    trips = []
    for b in final_bookings:
        expires_at = None
        if b.status == BookingStatus.CREATED:
            hold = active_holds.get((b.flight_id, b.seat_number))
            if not hold: continue
            expires_at = hold.expires_at.replace(tzinfo=timezone.utc)
            
        # Fetch history: include both user's own notes and official staff announcements for this flight
        from app.models.announcement import Announcement as AnnouncementModel
        staff_ids = [u.id for u in db.query(User.id).filter(User.role.in_([UserRole.STAFF, UserRole.ADMIN])).all()]
        
        history_announcements = db.query(AnnouncementModel).filter(
            AnnouncementModel.flight_id == b.flight_id,
            or_(
                AnnouncementModel.created_by == current_user.id, # My own journey events
                AnnouncementModel.created_by.in_(staff_ids)       # Official staff updates
            )
        ).order_by(AnnouncementModel.created_at.asc()).all()
        
        from app.schemas.announcement import Announcement as AnnouncementSchema
        history = [AnnouncementSchema.model_validate(h) for h in history_announcements]

        trips.append(Trip(
            id=b.id, passenger_id=b.passenger_id, flight_id=b.flight_id, flight=Flight.model_validate(b.flight),
            seat_number=b.seat_number, price=b.price, status=b.status.value, created_at=b.created_at,
            pnr=b.pnr or "-", gate=b.flight.gate, terminal=b.flight.terminal,
            payment_method=b.payment_method.value if b.payment_method else "CARD",
            expires_at=expires_at, checked_in=b.ticket.checked_in if b.ticket else False,
            qr_code=b.ticket.qr_code if b.ticket else None,
            first_name=b.first_name,
            last_name=b.last_name,
            passport_number=b.passport_number,
            date_of_birth=b.date_of_birth,
            confirmed_at=b.confirmed_at,
            checked_in_at=b.ticket.checked_in_at if b.ticket else None,
            transaction_id=b.payment.transaction_id if b.payment else None,
            history=history # Include history
        ))
    return trips
    
@router.get("/payments", response_model=List[PaymentTransaction], tags=["Passenger - Account & Profile"])
def get_payment_history(current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """История транзакций пассажира"""
    payments = db.query(PaymentModel).options(joinedload(PaymentModel.booking).joinedload(BookingModel.flight).joinedload(FlightModel.origin_airport), joinedload(PaymentModel.booking).joinedload(BookingModel.flight).joinedload(FlightModel.destination_airport)).filter(PaymentModel.passenger_id == current_user.id).order_by(PaymentModel.created_at.desc()).all()
    
    # Group by transaction_id
    grouped = {}
    for p in payments:
        if p.transaction_id not in grouped:
            grouped[p.transaction_id] = {
                "transaction_id": p.transaction_id,
                "amount": 0,
                "currency": p.currency,
                "method": p.method,
                "status": p.status,
                "created_at": p.created_at,
                "flight_info": p.flight_info, # Take first
                "items": []
            }
        
        grouped[p.transaction_id]["amount"] += p.amount
        grouped[p.transaction_id]["items"].append(PaymentItem(
            pnr=p.pnr,
            booking_id=p.booking_id,
            amount=p.amount,
            seat_number=p.booking.seat_number if p.booking else "?"
        ))
        
    return [PaymentTransaction(**g) for g in grouped.values()]


@router.post("/flights/search", response_model=List[Flight], summary="Поиск рейсов", description="Ищет доступные рейсы по городам и дате", tags=["Passenger - Search & Flights"])
def search_flights(search_data: FlightSearch, db: Session = Depends(get_db)):
    """Поиск рейсов"""
    flights = search_flights_service(db, search_data.origin_code, search_data.destination_code, search_data.departure_date)
    return [Flight.model_validate(f) for f in flights]




@router.get("/announcements", response_model=List[Announcement], summary="Список объявлений", description="Возвращает важные новости для пассажира и историю его рейсов", tags=["Passenger - Notifications"])
def get_announcements(current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Список объявлений и уведомлений"""
    bookings = db.query(BookingModel).filter(BookingModel.passenger_id == current_user.id).all()
    relevant_flight_ids = [b.flight_id for b in bookings if b.status in [BookingStatus.CONFIRMED, BookingStatus.CREATED]]
    
    now = datetime.utcnow()
    holds = db.query(SeatHoldModel).filter(SeatHoldModel.passenger_id == current_user.id, SeatHoldModel.expires_at > now).all()
    holds_map = { (h.flight_id, h.seat_number) for h in holds }
    
    for b in bookings:
        if b.status == BookingStatus.CREATED and (b.flight_id, b.seat_number) not in holds_map:
            b.status = BookingStatus.CANCELLED
            db.add(AnnouncementModel(title="Время истекло", message=f"Бронь места {b.seat_number} на рейс {b.flight.flight_number} истекла.", flight_id=b.flight_id, created_by=current_user.id))
        
        # New: Auto-announcement 1 hour before departure
        if b.status == BookingStatus.CONFIRMED:
            time_to_dep = b.flight.scheduled_departure - now
            if timedelta(minutes=0) < time_to_dep <= timedelta(minutes=65):
                # Check if we already announced this to this user
                existing_alert = db.query(AnnouncementModel).filter(
                    AnnouncementModel.flight_id == b.flight_id,
                    AnnouncementModel.created_by == current_user.id,
                    AnnouncementModel.title == "ВНИМАНИЕ: Вылет скоро"
                ).first()
                if not existing_alert:
                    db.add(AnnouncementModel(
                        title="ВНИМАНИЕ: Вылет скоро",
                        message=f"Ваш рейс {b.flight.flight_number} ({b.flight.departure_city} -> {b.flight.arrival_city}) вылетает через 1 час! Пожалуйста, пройдите к гейту {b.flight.gate or ''}.",
                        flight_id=b.flight_id,
                        created_by=current_user.id,
                        created_at=now
                    ))
    db.commit()
    
    staff_ids = [u.id for u in db.query(User.id).filter(User.role.in_([UserRole.STAFF, UserRole.ADMIN])).all()]
    announcements = db.query(AnnouncementModel).options(joinedload(AnnouncementModel.flight)).filter(
        or_(
            # 1. Global announcements for my flights (made by staff)
            and_(AnnouncementModel.flight_id.in_(relevant_flight_ids), AnnouncementModel.created_by.in_(staff_ids)),
            # 2. My own individual history entries for my flights
            and_(AnnouncementModel.flight_id.in_(relevant_flight_ids), AnnouncementModel.created_by == current_user.id),
            # 3. Flight-independent announcements (System news by staff or my own notes)
            and_(AnnouncementModel.flight_id.is_(None), or_(AnnouncementModel.created_by == current_user.id, AnnouncementModel.created_by.in_(staff_ids)))
        )
    ).order_by(AnnouncementModel.created_at.desc()).all()
    
    return [Announcement.model_validate(a) for a in announcements]


@router.post("/check-in", response_model=CheckInResponse, summary="Онлайн-регистрация", description="Регистрирует пассажира на рейс и выдает посадочный талон", tags=["Passenger - My Trips & Tickets"])
def check_in(request: CheckInRequest, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Пройти онлайн-регистрацию"""
    res = check_in_service(db, request.ticket_id, current_user.id)
    return CheckInResponse(success=True, message="Регистрация прошла успешно", boarding_pass=res["boarding_pass"])


@router.post("/bookings/{booking_id}/cancel", response_model=dict, tags=["Passenger - My Trips & Tickets"])
def cancel_booking(booking_id: int, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Отмена бронирования (возврат места)"""
    from app.models.booking import Ticket as TicketModel
    
    booking = db.query(BookingModel).filter(BookingModel.id == booking_id, BookingModel.passenger_id == current_user.id).first()
    if not booking or booking.status == BookingStatus.CANCELLED:
        raise HTTPException(status_code=404, detail="Бронирование не найдено или уже отменено")
    
    seat_number = booking.seat_number
    flight_id = booking.flight_id
    
    # Set booking status to cancelled
    booking.status = BookingStatus.CANCELLED
    
    # Delete any seat holds for this seat
    db.query(SeatHoldModel).filter(
        SeatHoldModel.flight_id == flight_id, 
        SeatHoldModel.seat_number == seat_number, 
        SeatHoldModel.passenger_id == current_user.id
    ).delete()
    
    # Delete associated ticket if exists
    db.query(TicketModel).filter(TicketModel.booking_id == booking_id).delete()
    
    # Create announcement about cancellation
    db.add(AnnouncementModel(
        title="Бронирование отменено", 
        message=f"Ваша бронь места {seat_number} была отменена. Место теперь доступно для других пассажиров.", 
        flight_id=flight_id, 
        created_by=current_user.id
    ))
    
    db.commit()
    return {"success": True, "message": f"Бронирование места {seat_number} отменено. Место освобождено."}


class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    passport_number: Optional[str] = None
    nationality: Optional[str] = None
    date_of_birth: Optional[str] = None


@router.put("/profile", response_model=UserProfile, tags=["Passenger - Account & Profile"])
def update_profile(user_data: UserUpdate, current_user: User = Depends(get_current_passenger), db: Session = Depends(get_db)):
    """Обновить персональные данные"""
    update_dict = user_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(current_user, field, value)
    if 'first_name' in update_dict or 'last_name' in update_dict:
        current_user.full_name = f"{current_user.first_name} {current_user.last_name}"
    db.commit()
    db.refresh(current_user)
    return current_user
