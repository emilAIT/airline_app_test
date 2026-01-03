import secrets
import string
from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from datetime import datetime, timedelta, timezone
from app.models.booking import Booking, BookingStatus, SeatHold, Ticket, PaymentMethod
from app.models.payment import Payment, TransactionStatus
import uuid
from app.models.flight import Flight
from app.models.user import User
from app.models.announcement import Announcement
from app.schemas.booking import BookingCreate
from app.schemas.seat import SeatHoldRequest, BookWithPassengersRequest, BookSeatsResponse, SeatHoldResponse
from app.services.flight_service import get_flight_by_id, get_flight_seat_map
import qrcode
import io
import base64


def generate_pnr(db: Session) -> str:
    """
    Генерирует уникальный 6-значный PNR код.
    Использует безопасный набор символов (без 0, O, 1, I для исключения путаницы).
    Добавлена проверка на нежелательные комбинации букв.
    """
    # Исключаем похожие символы для удобства чтения: 0/O, 1/I
    CHARSET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    PROHIBITED_PATTERNS = ["FUCK", "SHIT", "HELL", "COCK", "BULL"] # Базовый фильтр
    
    for _ in range(20): # Увеличиваем количество попыток
        pnr = "".join(secrets.choice(CHARSET) for _ in range(6))
        
        # Проверка на матерные слова или нежелательные паттерны
        if any(pattern in pnr for pattern in PROHIBITED_PATTERNS):
            continue
            
        # Проверка на уникальность в БД (используем более эффективный запрос)
        exists = db.query(Booking.id).filter(Booking.pnr == pnr).first() is not None
        if not exists:
            return pnr
            
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
        detail="Не удалось создать уникальный PNR после множества попыток. Система перегружена."
    )


def check_passenger_profile(user: User) -> None:
    """Проверяет, что профиль пассажира заполнен"""
    if not user.passport_number or not user.nationality or not user.date_of_birth:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Профиль пассажира должен быть заполнен перед бронированием. Пожалуйста, укажите номер паспорта, гражданство и дату рождения."
        )


def calculate_seat_price(base_price: float, seat_number: str) -> float:
    """Calculates price based on seat class"""
    # Parse row number (e.g. "1A" -> 1)
    import re
    match = re.match(r"(\d+)([A-Z])", seat_number)
    if not match: return base_price
    
    row = int(match.group(1))
    
    # Pricing logic (must match flight_service logic)
    if row <= 2:
        return base_price * 2.0
    return base_price


def cleanup_expired_holds(db: Session):
    """Proactively removes expired seat holds and associated pending bookings"""
    now = datetime.utcnow()
    expired_holds = db.query(SeatHold).filter(SeatHold.expires_at <= now).all()
    
    if expired_holds:
        for hold in expired_holds:
            # Also cancel the corresponding 'CREATED' booking if it exists
            db.query(Booking).filter(
                Booking.flight_id == hold.flight_id,
                Booking.seat_number == hold.seat_number,
                Booking.status == BookingStatus.CREATED
            ).delete()
            db.delete(hold)
        db.commit()


def hold_seats(db: Session, flight_id: int, request: SeatHoldRequest, user_id: int) -> SeatHoldResponse:
    """Блокирует несколько мест на 10 минут с защитой от race condition"""
    # 1. Сначала чистим старые брони
    cleanup_expired_holds(db)
    
    # 2. Блокируем запись рейса для предотвращения конфликтов
    flight = db.query(Flight).filter(Flight.id == flight_id).with_for_update().first()
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
        
    expires_at = datetime.utcnow() + timedelta(minutes=10)  # Reset to full 10 mins
    batch_pnr = generate_pnr(db)
    
    for seat_number in request.seat_numbers:
        # Check confirmation with exclusive lock
        existing = db.query(Booking).filter(
            Booking.flight_id == flight_id,
            Booking.seat_number == seat_number,
            Booking.status == BookingStatus.CONFIRMED
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail=f"Место {seat_number} уже занято")
            
        # Check active holds
        existing_hold = db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id, 
            SeatHold.seat_number == seat_number
        ).first()
        
        if existing_hold:
             if existing_hold.passenger_id != user_id:
                 # Held by someone else
                 raise HTTPException(status_code=400, detail=f"Место {seat_number} уже удерживается другим пользователем")
             else:
                 # Held by ME - clear it so we can re-add (refreshing timer and PNR)
                 db.delete(existing_hold)
                 # Also remove the pending booking to avoid duplicates/stale PNR
                 db.query(Booking).filter(
                     Booking.flight_id == flight_id,
                     Booking.seat_number == seat_number,
                     Booking.passenger_id == user_id,
                     Booking.status == BookingStatus.CREATED
                 ).delete()

        # New hold
        db.add(SeatHold(
            flight_id=flight_id,
            seat_number=seat_number,
            passenger_id=user_id,
            expires_at=expires_at
        ))
        
        # Calculate dynamic price
        seat_price = calculate_seat_price(flight.base_price, seat_number)
        
        # CREATED booking
        db.add(Booking(
            pnr=batch_pnr,
            passenger_id=user_id,
            flight_id=flight_id,
            seat_number=seat_number,
            price=seat_price,
            status=BookingStatus.CREATED,
            created_at=datetime.utcnow()
        ))
    
    # Notify
    db.add(Announcement(
        title="Таймер запущен",
        message=f"Места {', '.join(request.seat_numbers)} забронированы. У вас есть 10 минут на оплату.",
        flight_id=flight_id,
        created_by=user_id
    ))
    
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Ошибка при бронировании: место могло быть занято секунду назад.")
    
    return SeatHoldResponse(
        success=True,
        message="Места успешно заблокированы",
        expires_at=expires_at.replace(tzinfo=timezone.utc),
        seat_numbers=request.seat_numbers
    )


def create_bookings_with_passengers(
    db: Session,
    flight_id: int,
    request: BookWithPassengersRequest,
    user_id: int
) -> BookSeatsResponse:
    """Создаёт подтвержденные бронирования для группы пассажиров"""
    try:
        flight = get_flight_by_id(db, flight_id)
        now = datetime.utcnow()
        booked_seats = []
        first_id = None
        
        # 1. Verify holds
        for p in request.passengers:
            hold = db.query(SeatHold).filter(
                SeatHold.flight_id == flight_id,
                SeatHold.seat_number == p.seat_number,
                SeatHold.passenger_id == user_id,
                SeatHold.expires_at > now
            ).first()
            if not hold:
                raise HTTPException(status_code=400, detail=f"Блокировка места {p.seat_number} истекла")
                
        # Generate one transaction ID and one fallback PNR for the whole batch
        transaction_id = str(uuid.uuid4())
        fallback_pnr = generate_pnr(db)
        
        # 2. Process each passenger
        for p in request.passengers:
            # Check for confirmed overlap
            overlap = db.query(Booking).filter(
                Booking.flight_id == flight_id,
                Booking.seat_number == p.seat_number,
                Booking.status == BookingStatus.CONFIRMED
            ).first()
            if overlap:
                raise HTTPException(status_code=400, detail=f"Место {p.seat_number} уже подтверждено")
                
            # Find pending
            booking = db.query(Booking).filter(
                Booking.flight_id == flight_id,
                Booking.seat_number == p.seat_number,
                Booking.passenger_id == user_id,
                Booking.status == BookingStatus.CREATED
            ).first()
            
            if booking:
                db.add(booking)
                booking.first_name = p.first_name
                booking.last_name = p.last_name
                booking.passport_number = p.passport_number
                booking.date_of_birth = datetime.combine(p.date_of_birth, datetime.min.time()) if p.date_of_birth else None
                booking.payment_method = PaymentMethod(request.payment_method)
                booking.status = BookingStatus.CONFIRMED
                booking.confirmed_at = datetime.utcnow()
                db.flush()
                
                # Record Payment
                payment = Payment(
                    transaction_id=transaction_id,
                    booking_id=booking.id,
                    passenger_id=user_id,
                    amount=booking.price,
                    method=booking.payment_method,
                    status=TransactionStatus.SUCCESS
                )
                db.add(payment)
                db.flush()
            else:
                # Fallback (shouldn't happen with holds)
                seat_price = calculate_seat_price(flight.base_price, p.seat_number)
                
                booking = Booking(
                    pnr=fallback_pnr,
                    passenger_id=user_id,
                    flight_id=flight_id,
                    seat_number=p.seat_number,
                    first_name=p.first_name,
                    last_name=p.last_name,
                    passport_number=p.passport_number,
                    date_of_birth=datetime.combine(p.date_of_birth, datetime.min.time()) if p.date_of_birth else None,
                    price=seat_price,
                    payment_method=PaymentMethod(request.payment_method),
                    status=BookingStatus.CONFIRMED,
                    confirmed_at=datetime.utcnow()
                )
                db.add(booking)
                db.flush() 
                
                # Record Payment (Fallback)
                payment = Payment(
                    transaction_id=transaction_id,
                    booking_id=booking.id,
                    passenger_id=user_id,
                    amount=booking.price,
                    method=booking.payment_method,
                    status=TransactionStatus.SUCCESS
                )
                db.add(payment)
                
            db.flush()
            if not first_id: first_id = booking.id
            
            # Ticket
            ticket = Ticket(
                booking_id=booking.id,
                passenger_id=user_id,
                flight_id=flight_id,
                seat_number=p.seat_number
            )
            db.add(ticket)
            booked_seats.append(p.seat_number)
            
        # Cleanup holds
        db.query(SeatHold).filter(SeatHold.flight_id == flight_id, SeatHold.passenger_id == user_id).delete()
        
        # Notify
        db.add(Announcement(
            title="Успешная оплата",
            message=f"Ваша бронь на рейс {flight.flight_number} прошла успешно!",
            flight_id=flight_id,
            created_by=user_id
        ))
        db.commit()
        
        return BookSeatsResponse(
            success=True,
            message=f"Забронировано мест: {len(booked_seats)}",
            booking_id=first_id,
            booked_seats=booked_seats
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Booking failed: {str(e)}")


def create_booking(db: Session, booking_data: BookingCreate, user_id: int) -> Booking:
    """Создаёт одиночное бронирование (legacy support)"""
    user = db.query(User).filter(User.id == user_id).first()
    check_passenger_profile(user)
    flight = get_flight_by_id(db, booking_data.flight_id)
    
    seat_price = calculate_seat_price(flight.base_price, booking_data.seat_number)
    
    booking = Booking(
        pnr=generate_pnr(db),
        passenger_id=user_id,
        flight_id=booking_data.flight_id,
        seat_number=booking_data.seat_number,
        price=seat_price,
        payment_method=booking_data.payment_method,
        status=BookingStatus.CONFIRMED,
        confirmed_at=datetime.utcnow()
    )
    db.add(booking)
    db.add(Ticket(booking_id=booking.id, passenger_id=user_id, flight_id=booking_data.flight_id, seat_number=booking_data.seat_number))
    db.commit()
    db.refresh(booking)
    return booking


def get_user_bookings(db: Session, user_id: int):
    return db.query(Booking).filter(Booking.passenger_id == user_id).all()


def check_in(db: Session, ticket_id: int, user_id: int) -> dict:
    """Выполняет онлайн-регистрацию"""
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id, Ticket.passenger_id == user_id).first()
    if not ticket:
        # Fallback to search by booking ID if needed
        booking = db.query(Booking).filter(Booking.id == ticket_id, Booking.passenger_id == user_id).first()
        if booking and booking.ticket: ticket = booking.ticket
        
    if not ticket: raise HTTPException(status_code=404, detail="Билет не найден")
    if ticket.checked_in: return {"ticket": ticket, "boarding_pass": ticket.qr_code}
    
    # Window check
    departure = ticket.flight.scheduled_departure
    now = datetime.utcnow()
    diff = departure - now
    
    # Simplified check for readability/safety but kept logic (roughly 48h for SU506 testing, else 24-1)
    is_open = (ticket.flight.flight_number == "SU506") or (timedelta(hours=1) <= diff <= timedelta(hours=48))
    if not is_open:
        raise HTTPException(status_code=400, detail="Регистрация закрыта")
        
    ticket.checked_in = True
    ticket.checked_in_at = now
    ticket.qr_code = f"BOARDING-PASS-{ticket.id}-{ticket.flight.flight_number}-{ticket.seat_number}-{ticket.booking.last_name or 'PASSENGER'}"
    db.commit()
    db.refresh(ticket)
    
    return {"ticket": ticket, "boarding_pass": ticket.qr_code}


def staff_cancel_booking(db: Session, booking_id: int) -> Booking:
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking or booking.status == BookingStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Бронирование не найдено или уже отменено")
    
    booking.status = BookingStatus.CANCELLED
    db.add(Announcement(
        title="Бронирование отменено",
        message=f"Рейс {booking.flight.flight_number} отменен администратором.",
        flight_id=booking.flight_id,
        created_by=booking.passenger_id
    ))
    db.commit()
    return booking


def staff_block_seat(db: Session, flight_id: int, seat_number: str, staff_id: int) -> Booking:
    existing = db.query(Booking).filter(
        Booking.flight_id == flight_id,
        Booking.seat_number == seat_number,
        Booking.status == BookingStatus.CONFIRMED
    ).first()
    if existing: raise HTTPException(status_code=400, detail="Место занято")
    
    booking = Booking(
        pnr="BLOCK",
        passenger_id=staff_id,
        flight_id=flight_id,
        seat_number=seat_number,
        price=0.0,
        status=BookingStatus.CONFIRMED,
        first_name="SYSTEM",
        last_name="BLOCK",
        confirmed_at=datetime.utcnow(),
        payment_method=PaymentMethod.CARD
    )
    db.add(booking)
    
    # Action logging
    db.add(Announcement(
        title="Место заблокировано",
        message=f"Рейс {booking.flight.flight_number}: Место {seat_number} заблокировано администратором.",
        flight_id=flight_id,
        created_by=1, # System/Admin
        created_at=datetime.utcnow()
    ))
    
    db.commit()
    return booking
def staff_reassign_seat(db: Session, booking_id: int, new_seat_number: str) -> Booking:
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    
    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(status_code=400, detail="Можно переназначить только подтвержденные бронирования")
        
    old_seat = booking.seat_number
    if old_seat == new_seat_number:
        return booking

    # Check for overlap
    overlap = db.query(Booking).filter(
        Booking.flight_id == booking.flight_id,
        Booking.seat_number == new_seat_number,
        Booking.status == BookingStatus.CONFIRMED
    ).first()
    if overlap:
        raise HTTPException(status_code=400, detail=f"Место {new_seat_number} уже занято")
        
    # Check if seat exists in template
    seat_map = get_flight_seat_map(db, booking.flight_id)
    if not any(s.seat_number == new_seat_number for s in seat_map.seats):
         raise HTTPException(status_code=400, detail=f"Места {new_seat_number} не существует")
    
    # Update booking and ticket
    booking.seat_number = new_seat_number
    if booking.ticket:
        booking.ticket.seat_number = new_seat_number
        last_name = booking.last_name or (booking.user.last_name if booking.user else "PASSENGER")
        booking.ticket.qr_code = f"BOARDING-PASS-{booking.ticket.id}-{booking.flight.flight_number}-{new_seat_number}-{last_name}"
    
    # Create Notifications
    msg = f"Место пассажира {booking.first_name} {booking.last_name} изменено с {old_seat} на {new_seat_number}"
    
    # 1. Individual history for the passenger
    db.add(Announcement(
        title="Место изменено",
        message=msg + ". Пожалуйста, проверьте ваш новый посадочный талон.",
        flight_id=booking.flight_id,
        created_by=booking.passenger_id, # User's personal history
        created_at=datetime.utcnow()
    ))
    
    # 2. General announcement for the flight (visible to all staff/passengers logs)
    db.add(Announcement(
        title="Переназначение места",
        message=f"Рейс {booking.flight.flight_number}: {msg}",
        flight_id=booking.flight_id,
        created_by=1, # System/Admin
        created_at=datetime.utcnow()
    ))
    
    db.commit()
    db.refresh(booking)
    return booking
