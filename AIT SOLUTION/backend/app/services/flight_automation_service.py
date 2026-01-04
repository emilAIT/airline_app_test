"""
Сервис автоматизации управления рейсами по времени
"""

from datetime import datetime, timedelta
from sqlmodel import Session, select
from app.models import Flight, FlightStatus, Booking, BookingStatus, Ticket
from app.services.notification_service import NotificationService
import logging

logger = logging.getLogger(__name__)

class FlightAutomationService:
    def __init__(self, session: Session):
        self.session = session
        self.notification_service = NotificationService(session)

    def process_flight_status_updates(self):
        """
        Основной метод для обработки автоматических обновлений статусов рейсов
        """
        try:
            # Получаем текущее время
            now = datetime.now()
            logger.info(f"🤖 Автоматизация: Текущее время: {now}")
            
            # Обрабатываем каждый тип обновления
            boarding_count = self._update_to_boarding(now)
            departed_count = self._update_to_departed(now)
            landed_count = self._update_to_landed(now)
            finished_count = self._update_to_finished(now)
            
            # Коммитим все изменения
            self.session.commit()
            
            if boarding_count > 0 or departed_count > 0 or landed_count > 0 or finished_count > 0:
                msg = f"✅ Автоматизация: Обновлено рейсов - BOARDING: {boarding_count}, DEPARTED: {departed_count}, LANDED: {landed_count}, FINISHED: {finished_count}"
                logger.info(msg)
                print(msg, flush=True)
            else:
                logger.debug("🤖 Автоматизация: Нет рейсов для обновления")
            
        except Exception as e:
            logger.error(f"❌ Ошибка при автоматическом обновлении статусов рейсов: {e}", exc_info=True)
            self.session.rollback()
            raise

    def _update_to_boarding(self, now: datetime):
        """
        Обновляет статус рейсов на BOARDING за 1 час до вылета
        """
        try:
            # Находим рейсы, которые должны перейти в статус BOARDING
            # (за 1 час до вылета, если статус не CANCELLED)
            one_hour_from_now = now + timedelta(hours=1)
            
            flights_to_board = self.session.exec(
                select(Flight).where(
                    Flight.status.in_([FlightStatus.SCHEDULED, FlightStatus.DELAYED]),
                    Flight.scheduled_departure <= one_hour_from_now,
                    Flight.scheduled_departure > now  # Рейс еще не вылетел
                )
            ).all()
            
            if flights_to_board:
                logger.info(f"🔍 Найдено {len(flights_to_board)} рейсов для проверки BOARDING")
                for f in flights_to_board:
                    logger.info(f"  - {f.flight_number}: статус={f.status}, вылет={f.scheduled_departure}")
            
            updated_count = 0
            for flight in flights_to_board:
                # Проверяем, что рейс действительно должен перейти в BOARDING
                departure_time = flight.scheduled_departure
                time_until_departure = departure_time - now
                
                # Если до вылета <= 1 час, переводим в BOARDING
                if time_until_departure <= timedelta(hours=1):
                    old_status = flight.status
                    flight.status = FlightStatus.BOARDING
                    self.session.add(flight)
                    updated_count += 1
                    
                    logger.info(f"✈️ Рейс {flight.flight_number} переведен в статус BOARDING (было: {old_status}, до вылета: {time_until_departure})")
                    
                    # Отправляем уведомления всем пассажирам
                    try:
                        self.notification_service.notify_flight_update(
                            flight,
                            "Boarding Started",
                            f"Boarding has started for flight {flight.flight_number}. Please proceed to the gate."
                        )
                    except Exception as e:
                        logger.error(f"Ошибка при отправке уведомлений о начале посадки: {e}")
            
            return updated_count
                
        except Exception as e:
            logger.error(f"Ошибка при обновлении статусов на BOARDING: {e}", exc_info=True)
            raise

    def _update_to_departed(self, now: datetime):
        """
        Обновляет статус рейсов на DEPARTED когда время вылета наступило
        """
        try:
            # Находим рейсы в статусе BOARDING, время вылета которых уже наступило
            flights_to_depart = self.session.exec(
                select(Flight).where(
                    Flight.status == FlightStatus.BOARDING,
                    Flight.scheduled_departure <= now  # Время вылета уже наступило
                )
            ).all()
            
            if flights_to_depart:
                logger.info(f"🔍 Найдено {len(flights_to_depart)} рейсов для проверки DEPARTED")
                for f in flights_to_depart:
                    logger.info(f"  - {f.flight_number}: статус={f.status}, вылет={f.scheduled_departure}")
            
            updated_count = 0
            for flight in flights_to_depart:
                departure_time = flight.scheduled_departure
                
                # Если время вылета уже прошло, переводим в DEPARTED
                if departure_time <= now:
                    old_status = flight.status
                    flight.status = FlightStatus.DEPARTED
                    self.session.add(flight)
                    updated_count += 1
                    
                    logger.info(f"✈️ Рейс {flight.flight_number} переведен в статус DEPARTED (было: {old_status})")
                    
                    # Отправляем уведомления всем пассажирам
                    try:
                        self.notification_service.notify_flight_update(
                            flight,
                            "Flight Departed",
                            f"Flight {flight.flight_number} has departed. Have a safe journey!"
                        )
                    except Exception as e:
                        logger.error(f"Ошибка при отправке уведомлений о вылете: {e}")
            
            return updated_count
                
        except Exception as e:
            logger.error(f"Ошибка при обновлении статусов на DEPARTED: {e}", exc_info=True)
            raise

    def _update_to_landed(self, now: datetime):
        """
        Обновляет статус рейсов на LANDED когда до времени посадки осталось 10 минут
        """
        try:
            # Находим рейсы в статусе DEPARTED, до посадки которых осталось 10 минут или меньше
            ten_minutes_from_now = now + timedelta(minutes=10)
            
            flights_to_land = self.session.exec(
                select(Flight).where(
                    Flight.status == FlightStatus.DEPARTED,
                    Flight.scheduled_arrival <= ten_minutes_from_now,  # До посадки <= 10 минут
                    Flight.scheduled_arrival > now  # Рейс еще не приземлился
                )
            ).all()
            
            if flights_to_land:
                logger.info(f"🔍 Найдено {len(flights_to_land)} рейсов для проверки LANDED")
                for f in flights_to_land:
                    logger.info(f"  - {f.flight_number}: статус={f.status}, посадка={f.scheduled_arrival}")
            
            updated_count = 0
            for flight in flights_to_land:
                arrival_time = flight.scheduled_arrival
                time_until_arrival = arrival_time - now
                
                # Если до посадки <= 10 минут, переводим в LANDED
                if time_until_arrival <= timedelta(minutes=10):
                    old_status = flight.status
                    flight.status = FlightStatus.LANDED
                    self.session.add(flight)
                    updated_count += 1
                    
                    logger.info(f"✈️ Рейс {flight.flight_number} переведен в статус LANDED (было: {old_status}, до посадки: {time_until_arrival})")
                    
                    # Отправляем уведомления всем пассажирам
                    try:
                        self.notification_service.notify_flight_update(
                            flight,
                            "Flight Landing",
                            f"Flight {flight.flight_number} is landing. Please prepare for arrival."
                        )
                    except Exception as e:
                        logger.error(f"Ошибка при отправке уведомлений о посадке: {e}")
            
            return updated_count
                
        except Exception as e:
            logger.error(f"Ошибка при обновлении статусов на LANDED: {e}", exc_info=True)
            raise

    def _update_to_finished(self, now: datetime):
        """
        Обновляет статус рейсов на FINISHED когда наступает время прибытия (scheduled_arrival)
        """
        try:
            # Находим рейсы в статусе LANDED, время прибытия которых наступило
            flights_to_finish = self.session.exec(
                select(Flight).where(
                    Flight.status == FlightStatus.LANDED,
                    Flight.scheduled_arrival <= now  # Время прибытия наступило
                )
            ).all()
            
            if flights_to_finish:
                logger.info(f"🔍 Найдено {len(flights_to_finish)} рейсов для проверки FINISHED")
                for f in flights_to_finish:
                    logger.info(f"  - {f.flight_number}: статус={f.status}, прибытие={f.scheduled_arrival}")
            
            updated_count = 0
            for flight in flights_to_finish:
                arrival_time = flight.scheduled_arrival
                
                # Если время прибытия наступило, переводим в FINISHED
                if arrival_time <= now:
                    old_status = flight.status
                    flight.status = FlightStatus.FINISHED
                    self.session.add(flight)
                    updated_count += 1
                    
                    logger.info(f"✈️ Рейс {flight.flight_number} переведен в статус FINISHED (было: {old_status}, время прибытия: {arrival_time})")
                    
                    # Отправляем уведомления всем пассажирам
                    try:
                        self.notification_service.notify_flight_update(
                            flight,
                            "Flight Completed",
                            f"Flight {flight.flight_number} has been completed. Thank you for flying with us!"
                        )
                    except Exception as e:
                        logger.error(f"Ошибка при отправке уведомлений о завершении рейса: {e}")
            
            return updated_count
                
        except Exception as e:
            logger.error(f"Ошибка при обновлении статусов на FINISHED: {e}", exc_info=True)
            raise

    def _cleanup_completed_flights(self, now: datetime):
        """
        Удаляет рейсы, время посадки которых уже прошло (статус LANDED)
        """
        try:
            # Находим рейсы со статусом LANDED, время посадки которых уже прошло
            flights_to_delete = self.session.exec(
                select(Flight).where(
                    Flight.status == FlightStatus.LANDED,
                    Flight.scheduled_arrival <= now
                )
            ).all()
            
            deleted_count = 0
            for flight in flights_to_delete:
                # Проверяем время посадки
                arrival_time = flight.scheduled_arrival
                
                # Если время посадки уже прошло, удаляем рейс
                if arrival_time <= now:
                    flight_number = flight.flight_number
                    
                    # Удаляем связанные данные в правильном порядке
                    self._delete_flight_with_dependencies(flight)
                    deleted_count += 1
                    
                    logger.info(f"Удален завершенный рейс {flight_number} (время посадки прошло)")
            
            if deleted_count > 0:
                logger.info(f"Удалено {deleted_count} завершенных рейсов")
                
        except Exception as e:
            logger.error(f"Ошибка при удалении завершенных рейсов: {e}")
            raise

    def _cleanup_overdue_flights(self, now: datetime):
        """
        Удаляет рейсы, время посадки которых уже наступило, независимо от статуса
        (кроме уже удаленных LANDED и CANCELLED)
        """
        try:
            # Находим рейсы, время посадки которых уже наступило или совпадает с текущим временем
            # но которые еще не в статусе LANDED или CANCELLED
            overdue_flights = self.session.exec(
                select(Flight).where(
                    Flight.status.not_in([FlightStatus.LANDED, FlightStatus.CANCELLED]),
                    Flight.scheduled_arrival <= now  # Время посадки уже наступило
                )
            ).all()
            
            deleted_count = 0
            for flight in overdue_flights:
                # Проверяем время посадки
                arrival_time = flight.scheduled_arrival
                
                # Если время посадки уже наступило, удаляем рейс
                if arrival_time <= now:
                    flight_number = flight.flight_number
                    old_status = flight.status
                    
                    # Удаляем связанные данные в правильном порядке
                    self._delete_flight_with_dependencies(flight)
                    deleted_count += 1
                    
                    logger.info(f"Удален просроченный рейс {flight_number} (статус: {old_status}, время посадки: {arrival_time}, текущее время: {now})")
            
            if deleted_count > 0:
                logger.info(f"Удалено {deleted_count} просроченных рейсов")
                
        except Exception as e:
            logger.error(f"Ошибка при удалении просроченных рейсов: {e}")
            raise

    def _cleanup_cancelled_flights(self):
        """
        Удаляет все рейсы со статусом CANCELLED
        """
        try:
            # Находим все отмененные рейсы
            cancelled_flights = self.session.exec(
                select(Flight).where(Flight.status == FlightStatus.CANCELLED)
            ).all()
            
            deleted_count = 0
            for flight in cancelled_flights:
                flight_number = flight.flight_number
                
                # Удаляем связанные данные в правильном порядке
                self._delete_flight_with_dependencies(flight)
                deleted_count += 1
                
                logger.info(f"Удален отмененный рейс {flight_number}")
            
            if deleted_count > 0:
                logger.info(f"Удалено {deleted_count} отмененных рейсов")
                
        except Exception as e:
            logger.error(f"Ошибка при удалении отмененных рейсов: {e}")
            raise

    def _delete_flight_with_dependencies(self, flight: Flight):
        """
        Безопасно удаляет рейс со всеми связанными данными
        """
        try:
            # 1. Удаляем все билеты для бронирований этого рейса
            bookings = self.session.exec(
                select(Booking).where(Booking.flight_id == flight.id)
            ).all()
            
            for booking in bookings:
                # Удаляем билеты
                tickets = self.session.exec(
                    select(Ticket).where(Ticket.booking_id == booking.id)
                ).all()
                
                for ticket in tickets:
                    self.session.delete(ticket)
                
                # Удаляем бронирование
                self.session.delete(booking)
            
            # 2. Удаляем сам рейс
            self.session.delete(flight)
            
        except Exception as e:
            logger.error(f"Ошибка при удалении рейса {flight.flight_number} с зависимостями: {e}")
            raise

    def get_automation_status(self):
        """
        Возвращает статистику автоматизации рейсов
        """
        try:
            now = datetime.now()
            
            # Подсчитываем рейсы по статусам
            stats = {}
            for status in FlightStatus:
                count = self.session.exec(
                    select(Flight).where(Flight.status == status)
                ).all()
                stats[status.value] = len(count)
            
            # Рейсы, которые скоро перейдут в BOARDING (за 1 час до вылета)
            one_hour_from_now = now + timedelta(hours=1)
            boarding_soon = self.session.exec(
                select(Flight).where(
                    Flight.status.in_([FlightStatus.SCHEDULED, FlightStatus.DELAYED]),
                    Flight.scheduled_departure <= one_hour_from_now,
                    Flight.scheduled_departure > now
                )
            ).all()
            
            # Рейсы, которые скоро перейдут в LANDED (за 10 минут до посадки)
            ten_minutes_from_now = now + timedelta(minutes=10)
            landing_soon = self.session.exec(
                select(Flight).where(
                    Flight.status == FlightStatus.DEPARTED,
                    Flight.scheduled_arrival <= ten_minutes_from_now,
                    Flight.scheduled_arrival > now
                )
            ).all()
            
            return {
                "current_time": now.isoformat(),
                "flight_counts_by_status": stats,
                "boarding_soon": len(boarding_soon),
                "landing_soon": len(landing_soon)
            }
            
        except Exception as e:
            logger.error(f"Ошибка при получении статистики автоматизации: {e}")
            return {"error": str(e)}