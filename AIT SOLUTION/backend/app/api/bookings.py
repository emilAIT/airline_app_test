from fastapi import APIRouter, Depends, HTTPException, Body
from sqlmodel import Session
from typing import List, Dict, Any
import json
from app.database import get_session
from app.models.schema import Booking, User, BookingRead
from app.core.deps import get_current_user
from app.services.all_services import BookingService, PaymentService

router = APIRouter(prefix="/bookings", tags=["bookings"])

def _serialize_booking(booking: Booking) -> Dict[str, Any]:
    """Конвертирует Booking объект в словарь для JSON сериализации"""
    try:
        result = {
            "id": booking.id,
            "user_id": booking.user_id,
            "flight_id": booking.flight_id,
            "booking_reference": booking.booking_reference,
            "status": booking.status.value,
            "total_price": booking.total_price,
            "passengers_count": booking.passengers_count,
            "created_at": booking.created_at.isoformat() if booking.created_at else None,
            "flight": None,
            "tickets": []
        }
        
        # Сериализуем flight
        if hasattr(booking, 'flight') and booking.flight:
            try:
                flight_data = {
                    "id": booking.flight.id,
                    "flight_number": booking.flight.flight_number,
                    "departure_airport_id": booking.flight.departure_airport_id,
                    "arrival_airport_id": booking.flight.arrival_airport_id,
                    "scheduled_departure": booking.flight.scheduled_departure.isoformat() if booking.flight.scheduled_departure else None,
                    "scheduled_arrival": booking.flight.scheduled_arrival.isoformat() if booking.flight.scheduled_arrival else None,
                    "status": booking.flight.status.value,
                    "airplane_id": booking.flight.airplane_id,
                    "base_price": booking.flight.base_price,
                    "owner_id": booking.flight.owner_id,
                    "check_in_opens": booking.flight.check_in_opens.isoformat() if booking.flight.check_in_opens else None,
                    "check_in_closes": booking.flight.check_in_closes.isoformat() if booking.flight.check_in_closes else None,
                    "gate_departure": getattr(booking.flight, 'gate_departure', None),
                    "gate_arrival": getattr(booking.flight, 'gate_arrival', None),
                    "departure_airport": None,
                    "arrival_airport": None,
                    "airplane": None
                }
                
                # Сериализуем departure_airport
                if hasattr(booking.flight, 'departure_airport') and booking.flight.departure_airport:
                    try:
                        flight_data["departure_airport"] = {
                            "id": booking.flight.departure_airport.id,
                            "code": booking.flight.departure_airport.code,
                            "name": booking.flight.departure_airport.name,
                            "city": booking.flight.departure_airport.city,
                            "country": booking.flight.departure_airport.country,
                            "timezone": booking.flight.departure_airport.timezone
                        }
                    except Exception as e:
                        print(f"Error serializing departure_airport: {e}")
                
                # Сериализуем arrival_airport
                if hasattr(booking.flight, 'arrival_airport') and booking.flight.arrival_airport:
                    try:
                        flight_data["arrival_airport"] = {
                            "id": booking.flight.arrival_airport.id,
                            "code": booking.flight.arrival_airport.code,
                            "name": booking.flight.arrival_airport.name,
                            "city": booking.flight.arrival_airport.city,
                            "country": booking.flight.arrival_airport.country,
                            "timezone": booking.flight.arrival_airport.timezone
                        }
                    except Exception as e:
                        print(f"Error serializing arrival_airport: {e}")
                
                # Сериализуем airplane
                if hasattr(booking.flight, 'airplane') and booking.flight.airplane:
                    try:
                        flight_data["airplane"] = {
                            "id": booking.flight.airplane.id,
                            "model": booking.flight.airplane.model,
                            "registration": booking.flight.airplane.registration,
                            "manufacturer": booking.flight.airplane.manufacturer,
                            "total_seats": booking.flight.airplane.total_seats,
                            "economy_seats": getattr(booking.flight.airplane, 'economy_seats', 0),
                            "business_seats": getattr(booking.flight.airplane, 'business_seats', 0)
                        }
                    except Exception as e:
                        print(f"Error serializing airplane: {e}")
                
                result["flight"] = flight_data
            except Exception as e:
                print(f"Error serializing flight: {e}")
        
        # Сериализуем tickets
        if hasattr(booking, 'tickets') and booking.tickets:
            try:
                result["tickets"] = [
                    {
                        "id": ticket.id,
                        "passenger_id": ticket.passenger_id,
                        "seat_id": ticket.seat_id,
                        "ticket_number": ticket.ticket_number,
                        "passenger_first_name": getattr(ticket, 'passenger_first_name', None),
                        "passenger_last_name": getattr(ticket, 'passenger_last_name', None),
                        "passenger_phone": getattr(ticket, 'passenger_phone', None),
                        "passenger_passport_number": getattr(ticket, 'passenger_passport_number', None),
                        "passenger_nationality": getattr(ticket, 'passenger_nationality', None)
                    }
                    for ticket in booking.tickets
                ]
            except Exception as e:
                print(f"Error serializing tickets: {e}")
        
        return result
    except Exception as e:
        print(f"Error serializing booking {booking.id if booking else 'None'}: {e}")
        import traceback
        traceback.print_exc()
        # Возвращаем минимальную информацию вместо ошибки
        return {
            "id": booking.id if booking else None,
            "user_id": booking.user_id if booking else None,
            "flight_id": booking.flight_id if booking else None,
            "booking_reference": booking.booking_reference if booking else None,
            "status": str(booking.status) if booking else None,
            "total_price": booking.total_price if booking else 0,
            "passengers_count": booking.passengers_count if booking else 0,
            "created_at": booking.created_at.isoformat() if booking and booking.created_at else None,
            "flight": None,
            "tickets": []
        }

@router.get("/")
# Назначение: Получить бронирования текущего пользователя
# Принимает: текущий пользователь из токена
# Возвращает: список бронирований с связанными данными
def list_my_bookings(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    try:
        service = BookingService(session)
        bookings = service.get_user_bookings(current_user.id)
        # Конвертируем в dict для корректной сериализации
        result = []
        for booking in bookings:
            try:
                serialized = _serialize_booking(booking)
                result.append(serialized)
            except Exception as e:
                print(f"Failed to serialize booking {booking.id}: {e}")
                import traceback
                traceback.print_exc()
                # Пропускаем проблемное бронирование, но продолжаем обработку остальных
                continue
        return result
    except Exception as e:
        print(f"Error in list_my_bookings: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/", response_model=BookingRead)
# Назначение: Создать групповое бронирование с персональными данными пассажиров
# Принимает: flight_id, passengers (list)
# Возвращает: созданное бронирование
def create_booking(
    data: dict = Body(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    try:
        service = BookingService(session)
        return service.create_booking(
            flight_id=data.get("flight_id"),
            user_id=current_user.id,
            passengers=data.get("passengers"),
            seat_id=data.get("seat_id"),
            passengers_count=data.get("passengers_count", 1)
        )
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/{booking_id}/pay")
# Назначение: Оплатить бронирование владельца (поля карты не скрываются на UI)
# Принимает: booking_id, данные карты
# Возвращает: статус оплаты
def pay_booking(
    booking_id: int,
    data: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = PaymentService(session)
    return service.process_dummy_payment(booking_id, data, current_user)

import logging
logger = logging.getLogger(__name__)

@router.post("/{booking_id}/checking")
# Назначение: Предполетная проверка группы билетов
# Принимает: booking_id, владельца бронирования
# Возвращает: результат проверки/QR
def checking_booking(
    booking_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    import sys
    print("\n" + "="*80, flush=True)
    print(f"🔴🔴🔴 CHECKING ENDPOINT CALLED - booking_id={booking_id} 🔴🔴🔴", flush=True)
    print(f"   user_id={current_user.id}, email={current_user.email}", flush=True)
    print("="*80 + "\n", flush=True)
    sys.stdout.flush()
    logger.info(f"=== CHECKING ENDPOINT CALLED ===")
    logger.info(f"booking_id={booking_id}, user_id={current_user.id}, user_email={current_user.email}")
    try:
        service = BookingService(session)
        logger.info(f"Service created, calling perform_checking...")
        result = service.perform_checking(booking_id, current_user)
        logger.info(f"perform_checking returned: success={result.get('success')}")
        return result
    except HTTPException as he:
        logger.error(f"HTTPException in checking_booking: status={he.status_code}, detail={he.detail}")
        raise
    except Exception as e:
        logger.error(f"EXCEPTION in checking_booking endpoint: {type(e).__name__}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/{booking_id}/cancel")
# Назначение: Отменить бронирование, если до рейса больше 24 часов
# Принимает: booking_id, текущего пользователя
# Возвращает: результат отмены с освобождением мест
def cancel_booking(
    booking_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    try:
        service = BookingService(session)
        result = service.cancel_booking(booking_id, current_user)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in cancel_booking: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{booking_id}/ticket-details")
# Назначение: Получить детали билета после check-in с QR-кодом и полной информацией
# Принимает: booking_id, текущего пользователя
# Возвращает: полную информацию о билете, рейсе, местах и QR-коды
def get_ticket_details(
    booking_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    try:
        service = BookingService(session)
        result = service.get_ticket_details(booking_id, current_user)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_ticket_details: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/tickets/{ticket_id}/reassign-seat")
# Назначение: Пересадить пассажира на другое место (staff only)
# Принимает: ticket_id, new_seat_id в теле запроса
# Возвращает: результат пересадки
def reassign_passenger_seat(
    ticket_id: int,
    data: dict = Body(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    try:
        service = BookingService(session)
        new_seat_id = data.get("new_seat_id")
        if not new_seat_id:
            raise HTTPException(status_code=400, detail="new_seat_id is required")
        result = service.reassign_passenger_seat(ticket_id, new_seat_id, current_user)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in reassign_passenger_seat: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
