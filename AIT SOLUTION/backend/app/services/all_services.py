from sqlmodel import Session, select
from sqlalchemy.orm import joinedload, aliased, selectinload
from fastapi import HTTPException
from datetime import datetime, timedelta
import uuid
from app.models import (
    User, UserRole, UserStatus, Airplane, Flight, Airport, 
    Booking, BookingStatus, FlightStatus, Ticket, SeatTemplate,
    Notification, NotificationType, SeatClass
)
from app.core.security import get_password_hash
from app.services.notification_service import NotificationService

class UserService:
    def __init__(self, session: Session):
        self.session = session

    def register_user(self, data: dict):
        """Register a new user with validation."""
        email = data.get("email")
        password = data.get("password")
        role = data.get("role", UserRole.PASSENGER)
        
        # Validate input
        if not email or not password:
            raise HTTPException(
                status_code=400,
                detail="Email and password are required"
            )
        
        # Basic email validation
        if "@" not in email or "." not in email:
            raise HTTPException(
                status_code=400,
                detail="Invalid email format"
            )
        
        # Check if user already exists
        existing_user = self.session.exec(select(User).where(User.email == email)).first()
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="User with this email already exists"
            )
        
        # Password validation is done in get_password_hash
        user = User(
            email=email,
            hashed_password=get_password_hash(password),
            role=role,
            status=UserStatus.PENDING_APPROVAL if role == UserRole.STAFF else UserStatus.ACTIVE
        )
        self.session.add(user)
        self.session.commit()
        self.session.refresh(user)
        return user

    def get_pending_staff(self, current_user: User):
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(status_code=403, detail="Forbidden")
        return self.session.exec(select(User).where(User.status == UserStatus.PENDING_APPROVAL)).all()

    # Назначение: Получить сводку по всем пользователям/персоналу для администратора
    # Принимает: текущего пользователя (должен быть админ)
    # Возвращает: список словарей с ролями, статусом и привязанными рейсами/самолетами
    def get_all_users_summary(self, current_user: User):
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(status_code=403, detail="Forbidden")
        users = self.session.exec(select(User)).all()
        summary = []
        for user in users:
            flights = []
            airplanes = []
            if user.role == UserRole.STAFF:
                flights = self.session.exec(select(Flight).where(Flight.owner_id == user.id)).all()
                airplanes = self.session.exec(select(Airplane).where(Airplane.owner_id == user.id)).all()
            summary.append({
                "id": user.id,
                "email": user.email,
                "role": user.role,
                "status": user.status,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "flights": [{"id": f.id, "number": f.flight_number} for f in flights],
                "airplanes": [{"id": a.id, "registration": a.registration} for a in airplanes]
            })
        return summary

    def approve_staff(self, user_id: int, current_user: User):
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(status_code=403, detail="Forbidden")
        user = self.session.get(User, user_id)
        if not user: raise HTTPException(status_code=404)
        user.status = UserStatus.ACTIVE
        self.session.add(user)
        self.session.commit()
        return {"message": "Approved"}

    # Назначение: Отклонить заявку стаффа администратором
    # Принимает: идентификатор пользователя и текущего админа
    # Возвращает: подтверждение
    def reject_staff(self, user_id: int, current_user: User):
        if current_user.role != UserRole.ADMIN:
            raise HTTPException(status_code=403, detail="Forbidden")
        user = self.session.get(User, user_id)
        if not user: raise HTTPException(status_code=404)
        user.status = UserStatus.REJECTED
        self.session.add(user)
        self.session.commit()
        return {"message": "Rejected"}

class AirportService:
    def __init__(self, session: Session):
        self.session = session

    def create_airport(self, data: dict, current_user: User):
        # ONLY Staff can create airports (as per user request: Admin only approves staff)
        if current_user.role != UserRole.STAFF:
            raise HTTPException(status_code=403, detail="Only Staff can create airports")
        
        # Ensure code is provided (IATA 3-letter code)
        if not data.get("code"):
            # If not provided, generate a basic one or raise error. 
            # I'll raise error as it's a unique index in DB.
            raise HTTPException(status_code=400, detail="Airport code (IATA) is required")

        if not data.get("timezone"):
            data["timezone"] = "UTC"

        airport = Airport(**data)
        self.session.add(airport)
        self.session.commit()
        self.session.refresh(airport)
        return airport

    def get_airports(self):
        return self.session.exec(select(Airport)).all()

class AirplaneService:
    def __init__(self, session: Session):
        self.session = session

    def create_airplane(self, data: dict, owner: User):
        # Validation
        model = data.get("model")
        total_seats = data.get("total_seats")
        registration = data.get("registration")
        manufacturer = data.get("manufacturer")

        if not model:
            raise HTTPException(status_code=400, detail="Model is required")
        if not manufacturer:
            raise HTTPException(status_code=400, detail="Manufacturer is required")
        if total_seats is None or total_seats < 1:
            raise HTTPException(status_code=400, detail="Total seats must be at least 1")
        if not registration:
            raise HTTPException(status_code=400, detail="Registration number is required")

        # Admin NO LONGER creates airplanes, only Staff
        if owner.role != UserRole.STAFF:
            raise HTTPException(status_code=403, detail="Only Staff can register airplanes")
        if owner.status != UserStatus.ACTIVE:
            raise HTTPException(status_code=403, detail="Staff account not approved")
        
        # Ensure rows and seats_per_row are set (for seat generation)
        spr = data.get("seats_per_row", 6)
        rows = data.get("rows_count", (total_seats + spr - 1) // spr)
        
        data["seats_per_row"] = spr
        data["rows_count"] = rows
        
        airplane = Airplane(**data)
        airplane.owner_id = owner.id
        self.session.add(airplane)
        self.session.commit()
        self.session.refresh(airplane)

        # Generate EXACTLY total_seats as templates
        seat_letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        
        seats_created = 0
        for row in range(1, rows + 1):
            for i in range(spr):
                if seats_created >= total_seats:
                    break
                letter = seat_letters[i % len(seat_letters)]
                
                # Assign seat class based on index (economy/business only)
                s_class = SeatClass.BUSINESS if seats_created < airplane.business_seats else SeatClass.ECONOMY
                
                seat = SeatTemplate(
                    airplane_id=airplane.id,
                    row_number=row,
                    seat_letter=letter,
                    seat_class=s_class
                )
                self.session.add(seat)
                seats_created += 1
            if seats_created >= total_seats:
                break
        
        self.session.commit()
        return airplane

    def get_airplanes(self, user: User):
        if user.role == UserRole.ADMIN:
            return self.session.exec(select(Airplane)).all()
        return self.session.exec(select(Airplane).where(Airplane.owner_id == user.id)).all()

    def delete_airplane(self, airplane_id: int, current_user: User):
        airplane = self.session.get(Airplane, airplane_id)
        if not airplane:
            raise HTTPException(status_code=404, detail="Airplane not found")
        
        # Ownership check
        if airplane.owner_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only delete airplanes you registered")
        
        # Проверяем, можно ли удалить самолет
        # Можно удалить только если у самолета нет рейсов ИЛИ все рейсы имеют статус FINISHED
        flights = self.session.exec(select(Flight).where(Flight.airplane_id == airplane.id)).all()
        
        # Если есть рейсы, проверяем их статусы
        if flights:
            non_finished_flights = [f for f in flights if f.status != FlightStatus.FINISHED]
            if non_finished_flights:
                # Формируем список рейсов с их статусами для более информативного сообщения
                flights_info = ", ".join([f"{f.flight_number} ({f.status.value})" for f in non_finished_flights])
                raise HTTPException(
                    status_code=400, 
                    detail=f"Cannot delete airplane: The airplane has {len(non_finished_flights)} flight(s) that are not finished: {flights_info}. Only airplanes with no flights or all flights with FINISHED status can be deleted."
                )
        
        # Удаляем все связанные данные в правильном порядке
        deleted_items = {"flights": 0, "bookings": 0, "tickets": 0, "seat_templates": 0}
        
        # 1. Удаляем все рейсы и связанные с ними данные
        for flight in flights:
            # Удаляем все бронирования для этого рейса
            bookings = self.session.exec(select(Booking).where(Booking.flight_id == flight.id)).all()
            for booking in bookings:
                # Удаляем билеты
                tickets = self.session.exec(select(Ticket).where(Ticket.booking_id == booking.id)).all()
                for ticket in tickets:
                    self.session.delete(ticket)
                    deleted_items["tickets"] += 1
                # Удаляем бронирование
                self.session.delete(booking)
                deleted_items["bookings"] += 1
            
            # Удаляем рейс
            self.session.delete(flight)
            deleted_items["flights"] += 1
        
        # 2. Удаляем все шаблоны мест (SeatTemplate)
        seat_templates = self.session.exec(select(SeatTemplate).where(SeatTemplate.airplane_id == airplane.id)).all()
        for seat_template in seat_templates:
            self.session.delete(seat_template)
            deleted_items["seat_templates"] += 1
        
        # 3. Теперь можно безопасно удалить самолет
        self.session.delete(airplane)
        self.session.commit()
        
        return {
            "status": "success", 
            "message": f"Airplane deleted successfully",
            "deleted": deleted_items
        }

class FlightService:
    def __init__(self, session: Session):
        self.session = session

    def _available_seats_for_flight(self, flight: Flight) -> int:
        # Подсчет свободных мест с учетом всех активных бронирований
        airplane = flight.airplane or self.session.get(Airplane, flight.airplane_id)
        total_seats = airplane.total_seats if airplane else 0
        reserved_counts = self.session.exec(
            select(Booking.passengers_count).where(
                Booking.flight_id == flight.id,
                Booking.status.notin_([BookingStatus.CANCELLED, BookingStatus.REFUNDED])
            )
        ).all()
        reserved_total = sum(reserved_counts) if reserved_counts else 0
        available = max(total_seats - reserved_total, 0)
        return available

    def create_flight(self, data: dict, owner: User):
        # Проверяем наличие обязательных gate полей
        if not data.get("gate_departure") or not data.get("gate_arrival"):
            raise HTTPException(status_code=400, detail="Gate departure and arrival are required")
        # 1. Check if airplane exists
        airplane_id = data.get("airplane_id")
        if not airplane_id:
            raise HTTPException(status_code=400, detail="Airplane ID is required")
            
        airplane = self.session.get(Airplane, airplane_id)
        if not airplane:
            raise HTTPException(status_code=404, detail="Airplane not found")
            
        # 1.5. Check if airports exist
        arrival_airport_id = data.get("arrival_airport_id")
        departure_airport_id = data.get("departure_airport_id")
        
        
        if not self.session.get(Airport, arrival_airport_id):
            raise HTTPException(status_code=404, detail=f"Arrival airport (ID: {arrival_airport_id}) not found")
        if not self.session.get(Airport, departure_airport_id):
            raise HTTPException(status_code=404, detail=f"Departure airport (ID: {departure_airport_id}) not found")

        # 2. ONLY Staff (and NOT Admin anymore) can create flights
        if owner.role != UserRole.STAFF:
            raise HTTPException(status_code=403, detail="Only Staff can create flights")
        if owner.status != UserStatus.ACTIVE:
            raise HTTPException(status_code=403, detail="Staff account not approved")
            
        if airplane.owner_id != owner.id:
            raise HTTPException(
                status_code=403, 
                detail="You can only create flights for airplanes you own"
            )
        
        # 3. Handle datetime strings if they come as strings
        for field in ["scheduled_departure", "scheduled_arrival", "check_in_opens", "check_in_closes"]:
            if isinstance(data.get(field), str):
                dt_str = data[field]
                # Убираем timezone из строки, если есть
                # Убираем Z в конце
                if dt_str.endswith('Z'):
                    dt_str = dt_str[:-1]
                # Убираем timezone offset (+HH:MM или -HH:MM)
                # Простой подход: ищем + или - после времени
                # Формат ISO: YYYY-MM-DDTHH:MM:SS+HH:MM или YYYY-MM-DDTHH:MM:SS-HH:MM
                if 'T' in dt_str:
                    t_index = dt_str.index('T')
                    # Ищем + после T (время)
                    if '+' in dt_str[t_index:]:
                        plus_index = dt_str.index('+', t_index)
                        dt_str = dt_str[:plus_index]
                    # Ищем - после времени (но не часть даты YYYY-MM-DD)
                    # Время имеет формат HH:MM:SS, поэтому проверяем количество - после T
                    elif dt_str.count('-', t_index) > 0:
                        # Разделяем по T и берем только дату и время без timezone
                        date_time = dt_str.split('T')
                        if len(date_time) == 2:
                            time_part = date_time[1]
                            # Если в времени есть - после :, это может быть timezone
                            if ':' in time_part:
                                # Берем только до первого - после последнего :
                                last_colon = time_part.rindex(':')
                                if '-' in time_part[last_colon + 1:]:
                                    dash_in_time = time_part.index('-', last_colon)
                                    time_part = time_part[:dash_in_time]
                            dt_str = f"{date_time[0]}T{time_part}"
                try:
                    data[field] = datetime.fromisoformat(dt_str)
                except ValueError:
                    # Если не удалось распарсить, пробуем без microseconds
                    if '.' in dt_str:
                        dt_str = dt_str.split('.')[0]
                        data[field] = datetime.fromisoformat(dt_str)
                    else:
                        raise

        # 3.5. Validate flight dates
        scheduled_departure = data.get("scheduled_departure")
        scheduled_arrival = data.get("scheduled_arrival")
        
        # Получаем текущее время в локальном часовом поясе для корректного сравнения
        now_local = datetime.now()
        
        # КРИТИЧЕСКАЯ ВАЛИДАЦИЯ: Проверяем время вылета (даже если arrival отсутствует)
        if scheduled_departure:
            dep_local = scheduled_departure
            # Время вылета должно быть минимум через 1 час от текущего времени, но не в прошлом
            if dep_local <= now_local:
                raise HTTPException(
                    status_code=400, 
                    detail="Flight departure time cannot be in the past"
                )
            if dep_local < now_local + timedelta(hours=1):
                raise HTTPException(
                    status_code=400, 
                    detail="Flight departure time must be at least 1 hour in the future"
                )
        
        if scheduled_departure and scheduled_arrival:
            # Время приходит как datetime объекты без timezone
            dep_local = scheduled_departure
            arr_local = scheduled_arrival
            
            # Проверяем, что время вылета раньше времени прибытия
            if dep_local >= arr_local:
                raise HTTPException(status_code=400, detail="Departure time must be before arrival time")
            
            # Время прибытия также не может быть в прошлом
            if arr_local <= now_local:
                raise HTTPException(
                    status_code=400, 
                    detail="Flight arrival time cannot be in the past"
                )
            
            # Проверяем минимальную продолжительность рейса (30 минут)
            flight_duration = arr_local - dep_local
            if flight_duration < timedelta(minutes=30):
                raise HTTPException(
                    status_code=400, 
                    detail="Flight duration must be at least 30 minutes"
                )

        # 4. Set defaults for check-in times (e.g., 24h before and 1h before)
        if not data.get("check_in_opens") and scheduled_departure:
            # Если рейс через 1-24 часа, открываем регистрацию сразу
            # Иначе за 24 часа до вылета
            time_until_departure = scheduled_departure - now_local
            if time_until_departure <= timedelta(hours=24):
                data["check_in_opens"] = now_local
            else:
                data["check_in_opens"] = scheduled_departure - timedelta(hours=24)
        
        if not data.get("check_in_closes") and scheduled_departure:
            # Если рейс через 5-10 минут, закрываем регистрацию за 3 минуты до вылета
            # Иначе за 1 час до вылета
            time_until_departure = scheduled_departure - now_local
            if time_until_departure <= timedelta(minutes=10):
                data["check_in_closes"] = scheduled_departure - timedelta(minutes=3)
            else:
                data["check_in_closes"] = scheduled_departure - timedelta(hours=1)

        # 5. Create flight
        flight = Flight(**data)
        flight.owner_id = owner.id
        self.session.add(flight)
        self.session.commit()
        
        # Re-fetch with options to ensure relationships are loaded for the response
        statement = select(Flight).where(Flight.id == flight.id).options(
            joinedload(Flight.departure_airport),
            joinedload(Flight.arrival_airport),
            joinedload(Flight.airplane)
        )
        return self.session.exec(statement).first()

    def get_all_flights(self, user: User = None, departure: str = None, arrival: str = None, date: str = None, passengers_count: int = None):
        statement = select(Flight).options(
            joinedload(Flight.departure_airport),
            joinedload(Flight.arrival_airport),
            joinedload(Flight.airplane)
        )
        
        if user and (user.role == UserRole.STAFF or user.role == UserRole.ADMIN):
            # Staff и Admin видят все свои рейсы независимо от статуса (включая FINISHED)
            if user.role == UserRole.STAFF:
                statement = statement.where(Flight.owner_id == user.id)
            # Admin видит все рейсы без фильтрации по owner_id
        else:
            # Passenger видит только рейсы со статусом SCHEDULED
            now = datetime.now()
            statement = statement.where(
                Flight.status == FlightStatus.SCHEDULED,
                # Рейс должен быть в будущем (время вылета > текущее время)
                Flight.scheduled_departure > now,
                # Регистрация не должна быть закрыта (если check_in_closes установлено)
                (Flight.check_in_closes.is_(None)) | (Flight.check_in_closes > now)
            )
            
        if departure:
            dep_alias = aliased(Airport)
            statement = statement.join(dep_alias, Flight.departure_airport_id == dep_alias.id).where(
                (dep_alias.city.ilike(f"%{departure}%")) | (dep_alias.code.ilike(f"%{departure}%"))
            )
        if arrival:
            arr_alias = aliased(Airport)
            statement = statement.join(arr_alias, Flight.arrival_airport_id == arr_alias.id).where(
                (arr_alias.city.ilike(f"%{arrival}%")) | (arr_alias.code.ilike(f"%{arrival}%"))
            )
        if date:
            try:
                # Сравнение только по дате вылета без времени
                target_date = datetime.fromisoformat(date).date()
                start_dt = datetime.combine(target_date, datetime.min.time())
                end_dt = datetime.combine(target_date, datetime.max.time())
                statement = statement.where(
                    Flight.scheduled_departure >= start_dt,
                    Flight.scheduled_departure <= end_dt
                )
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid date format, expected ISO date")
        
        flights = self.session.exec(statement).all()

        # Добавляем поле available_seats для каждого рейса
        flights_with_seats = []
        for flight in flights:
            # Создаем словарь из объекта рейса
            flight_dict = {
                "id": flight.id,
                "flight_number": flight.flight_number,
                "departure_airport_id": flight.departure_airport_id,
                "arrival_airport_id": flight.arrival_airport_id,
                "scheduled_departure": flight.scheduled_departure,
                "scheduled_arrival": flight.scheduled_arrival,
                "status": flight.status,
                "airplane_id": flight.airplane_id,
                "base_price": flight.base_price,
                "owner_id": flight.owner_id,
                "gate_departure": flight.gate_departure,
                "gate_arrival": flight.gate_arrival,
                "check_in_opens": flight.check_in_opens,
                "check_in_closes": flight.check_in_closes,
                # Добавляем вычисляемое поле
                "available_seats": self._available_seats_for_flight(flight),
                # Добавляем связанные объекты
                "departure_airport": flight.departure_airport,
                "arrival_airport": flight.arrival_airport,
                "airplane": flight.airplane
            }
            flights_with_seats.append(flight_dict)

        if passengers_count:
            flights_with_seats = [
                f for f in flights_with_seats 
                if f["available_seats"] >= passengers_count
            ]
        
        return flights_with_seats

    def get_flight_seat_map(self, flight_id: int):
        print(f"DEBUG: Getting seat map for flight {flight_id}")
        flight = self.session.get(Flight, flight_id)
        if not flight:
            print(f"DEBUG: Flight {flight_id} not found")
            raise HTTPException(status_code=404, detail="Flight not found")
            
        # Get all seat templates for the airplane
        print(f"DEBUG: Airplane ID: {flight.airplane_id}")
        seats = self.session.exec(
            select(SeatTemplate).where(SeatTemplate.airplane_id == flight.airplane_id)
        ).all()
        airplane = self.session.get(Airplane, flight.airplane_id)
        if airplane and len(seats) > airplane.total_seats:
            seats = seats[:airplane.total_seats]
        print(f"DEBUG: Found {len(seats)} seats")
        
        # Get all taken seats for this flight
        taken_seat_ids = self.session.exec(
            select(Ticket.seat_id)
            .join(Booking)
            .where(
                Booking.flight_id == flight_id,
                Booking.status.notin_([BookingStatus.CANCELLED, BookingStatus.REFUNDED]),
                Ticket.seat_id.is_not(None)
            )
        ).all()
        print(f"DEBUG: Taken seat IDs: {taken_seat_ids}")
        
        seat_map = []
        for seat in seats:
            # Приводим к двум классам: бизнес или эконом
            normalized_class = SeatClass.BUSINESS.value if seat.seat_class in [SeatClass.BUSINESS, SeatClass.FIRST] else SeatClass.ECONOMY.value
            seat_map.append({
                "id": seat.id,
                "row_number": seat.row_number,
                "seat_letter": seat.seat_letter,
                "seat_class": normalized_class,
                "is_available": seat.id not in taken_seat_ids
            })
        return seat_map

    def update_flight_gates(self, flight_id: int, gate_departure: str, gate_arrival: str, user: User):
        flight = self.session.get(Flight, flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        # Only staff/admin can update gates
        if user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise HTTPException(status_code=403, detail="Only staff can update flight gates")
        
        # Staff can only update their own flights
        if user.role == UserRole.STAFF and flight.owner_id != user.id:
            raise HTTPException(status_code=403, detail="You can only update your own flights")
        
        if user.role == UserRole.STAFF and user.status != UserStatus.ACTIVE:
            raise HTTPException(status_code=403, detail="Staff account not approved")
        
        if not gate_departure or not gate_arrival:
            raise HTTPException(status_code=400, detail="Both gates are required")

        old_gate_departure = flight.gate_departure
        old_gate_arrival = flight.gate_arrival
        
        flight.gate_departure = gate_departure
        flight.gate_arrival = gate_arrival
        self.session.add(flight)
        self.session.commit()

        # Send notifications to all passengers about gate change
        try:
            notification_service = NotificationService(self.session)
            notification_service.notify_gate_change(flight)
        except Exception as exc:
            print(f"Gate change notification failed: {exc}")

        statement = select(Flight).where(Flight.id == flight.id).options(
            joinedload(Flight.departure_airport),
            joinedload(Flight.arrival_airport),
            joinedload(Flight.airplane)
        )
        return self.session.exec(statement).first()

    def update_flight_status(self, flight_id: int, status: str, user: User):
        flight = self.session.get(Flight, flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        # Only staff/admin can update flight status
        if user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise HTTPException(status_code=403, detail="Only staff can update flight status")
        
        # Staff can only update their own flights
        if user.role == UserRole.STAFF and flight.owner_id != user.id:
            raise HTTPException(status_code=403, detail="You can only update your own flights")
        
        if user.role == UserRole.STAFF and user.status != UserStatus.ACTIVE:
            raise HTTPException(status_code=403, detail="Staff account not approved")
        
        # Validate status value
        try:
            # Convert string status to FlightStatus enum
            if isinstance(status, str):
                status_enum = FlightStatus(status.lower())
            else:
                status_enum = status
            
            old_status = flight.status
            flight.status = status_enum
            self.session.add(flight)
            self.session.commit()
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid status: {status}. Valid statuses are: {[s.value for s in FlightStatus]}"
            )
        
        # Send notifications to all passengers about flight status change
        try:
            notification_service = NotificationService(self.session)
            if status_enum == FlightStatus.DELAYED:
                notification_service.notify_flight_update(
                    flight, 
                    "Flight Delayed", 
                    f"Your flight {flight.flight_number} has been delayed. Please check the updated schedule."
                )
            elif status_enum == FlightStatus.CANCELLED:
                notification_service.notify_flight_update(
                    flight, 
                    "Flight Cancelled", 
                    f"We regret to inform you that flight {flight.flight_number} has been cancelled."
                )
            else:
                # Notify for any other status change
                notification_service.notify_flight_update(
                    flight, 
                    "Flight Status Update", 
                    f"Flight {flight.flight_number} status has been changed from {old_status.value} to {status_enum.value}."
                )
        except Exception as e:
            print(f"Error sending notifications: {e}")
        
        statement = select(Flight).where(Flight.id == flight_id).options(
            joinedload(Flight.departure_airport),
            joinedload(Flight.arrival_airport),
            joinedload(Flight.airplane)
        )
        return self.session.exec(statement).first()

    def get_flight_passengers(self, flight_id: int, user: User):
        """Get list of all passengers for a flight (staff only)"""
        flight = self.session.get(Flight, flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        # Only staff/admin can view passengers
        if user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise HTTPException(status_code=403, detail="Only staff can view passengers")
        
        if user.role == UserRole.STAFF and flight.owner_id != user.id:
            raise HTTPException(status_code=403, detail="You can only view passengers for your own flights")
        
        # Get all paid/checked-in bookings for this flight
        bookings = self.session.exec(
            select(Booking).where(
                Booking.flight_id == flight_id,
                Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
            )
        ).all()
        
        # Get all tickets with seat information
        passengers = []
        for booking in bookings:
            tickets = self.session.exec(
                select(Ticket).where(Ticket.booking_id == booking.id)
            ).all()
            
            for ticket in tickets:
                seat = None
                if ticket.seat_id:
                    seat = self.session.get(SeatTemplate, ticket.seat_id)
                
                passenger_info = {
                    "ticket_id": ticket.id,
                    "ticket_number": ticket.ticket_number,
                    "booking_reference": booking.booking_reference,
                    "passenger_name": f"{ticket.passenger_first_name or ''} {ticket.passenger_last_name or ''}".strip(),
                    "passenger_phone": ticket.passenger_phone,
                    "passenger_passport": ticket.passenger_passport_number,
                    "passenger_nationality": ticket.passenger_nationality,
                    "seat": {
                        "id": seat.id if seat else None,
                        "row": seat.row_number if seat else None,
                        "letter": seat.seat_letter if seat else None,
                        "class": seat.seat_class.value if seat else None
                    } if seat else None,
                    "booking_status": booking.status.value,
                    "user_id": booking.user_id
                }
                passengers.append(passenger_info)
        
        # Get statistics
        total_passengers = len(passengers)
        checked_in_count = len([p for p in passengers if p["booking_status"] == "checked_in"])
        
        return {
            "flight_id": flight_id,
            "flight_number": flight.flight_number,
            "total_passengers": total_passengers,
            "checked_in_count": checked_in_count,
            "passengers": passengers
        }

    def get_all_flights_passengers_summary(self, user: User):
        """Get summary of passengers for all flights (staff only)"""
        if user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise HTTPException(status_code=403, detail="Only staff can view passengers summary")
        
        # Get all flights owned by this staff or all flights for admin
        if user.role == UserRole.ADMIN:
            flights = self.session.exec(select(Flight)).all()
        else:
            flights = self.session.exec(
                select(Flight).where(Flight.owner_id == user.id)
            ).all()
        
        summary = []
        total_all_passengers = 0
        
        for flight in flights:
            bookings = self.session.exec(
                select(Booking).where(
                    Booking.flight_id == flight.id,
                    Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
                )
            ).all()
            
            passenger_count = sum(b.passengers_count for b in bookings)
            total_all_passengers += passenger_count
            
            summary.append({
                "flight_id": flight.id,
                "flight_number": flight.flight_number,
                "departure": flight.departure_airport.city if flight.departure_airport else None,
                "arrival": flight.arrival_airport.city if flight.arrival_airport else None,
                "departure_time": flight.scheduled_departure.isoformat() if flight.scheduled_departure else None,
                "passenger_count": passenger_count,
                "status": flight.status.value
            })
        
        return {
            "total_flights": len(summary),
            "total_passengers": total_all_passengers,
            "flights": summary
        }

class BookingService:
    def __init__(self, session: Session):
        self.session = session

    # Назначение: Проверяет доступность мест и создает групповое бронирование без овербукинга
    # Принимает: flight_id, user_id владельца, список passengers с seat_id/именами, опциональные устаревшие параметры
    # Возвращает: созданную сущность Booking с билетами
    def create_booking(self, flight_id: int, user_id: int, passengers: list = None, seat_id: int = None, passengers_count: int = 1):
        flight = self.session.get(Flight, flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")

        # Собираем список пассажиров (совместимость со старым API)
        passengers_payload = passengers or []
        if not passengers_payload:
            passengers_payload = [{
                "first_name": None,
                "last_name": None,
                "seat_id": seat_id,
                "seat_class": None
            }]
        # passengers_count из запроса должен совпадать с количеством карточек пассажиров
        if passengers_count and passengers_count != len(passengers_payload):
            raise HTTPException(status_code=400, detail="Passengers count does not match passengers payload")
        passengers_count = len(passengers_payload)

        # Проверяем, что рейс доступен для продажи
        if flight.status != FlightStatus.SCHEDULED:
            raise HTTPException(status_code=400, detail="Flight is not available for booking")
        
        # КРИТИЧЕСКАЯ ПРОВЕРКА: Нельзя покупать билеты, если регистрация уже закончена
        now = datetime.now()
        if flight.check_in_closes:
            check_in_closes = flight.check_in_closes
            
            if now > check_in_closes:
                raise HTTPException(
                    status_code=400, 
                    detail="Booking is no longer available - check-in period has ended"
                )

        # Фиксируем активные брони, чтобы избежать гонок при подсчете мест
        reserved_counts = self.session.exec(
            select(Booking.passengers_count).where(
                Booking.flight_id == flight_id,
                Booking.status.notin_([BookingStatus.CANCELLED, BookingStatus.REFUNDED])
            ).with_for_update()
        ).all()

        airplane = self.session.get(Airplane, flight.airplane_id)
        total_seats = airplane.total_seats if airplane else 0
        reserved_total = sum(reserved_counts) if reserved_counts else 0
        available_seats = max(total_seats - reserved_total, 0)
        if passengers_count > available_seats:
            raise HTTPException(status_code=400, detail="Not enough seats available for this flight")

        # Получаем карту мест для назначения конкретных кресел
        seat_templates = self.session.exec(
            select(SeatTemplate).where(SeatTemplate.airplane_id == flight.airplane_id)
        ).all()
        seat_lookup = {s.id: s for s in seat_templates}

        taken_seat_ids = set(self.session.exec(
            select(Ticket.seat_id)
            .join(Booking)
            .where(
                Booking.flight_id == flight_id,
                Booking.status.notin_([BookingStatus.CANCELLED, BookingStatus.REFUNDED]),
                Ticket.seat_id.is_not(None)
            ).with_for_update()  # Блокировка для предотвращения race condition
        ).all())

        assigned_seats = []
        for idx, pax in enumerate(passengers_payload):
            # Валидация: проверяем, что все обязательные поля заполнены для всех пассажиров
            first_name = pax.get("first_name")
            last_name = pax.get("last_name")
            phone = pax.get("phone")
            passport_number = pax.get("passport_number")
            nationality = pax.get("nationality")
            
            # Проверяем все обязательные поля
            missing_fields = []
            if not first_name or not first_name.strip():
                missing_fields.append("first_name")
            if not last_name or not last_name.strip():
                missing_fields.append("last_name")
            if not phone or not phone.strip():
                missing_fields.append("phone")
            if not passport_number or not passport_number.strip():
                missing_fields.append("passport_number")
            if not nationality or not nationality.strip():
                missing_fields.append("nationality")
            
            if missing_fields:
                raise HTTPException(
                    status_code=400,
                    detail=f"Missing required fields for passenger {idx + 1}: {', '.join(missing_fields)}"
                )
            requested_seat_id = pax.get("seat_id")
            preferred_class = pax.get("seat_class")
            if preferred_class and isinstance(preferred_class, str):
                preferred_class = SeatClass(preferred_class)

            if requested_seat_id:
                seat_obj = seat_lookup.get(requested_seat_id)
                if not seat_obj:
                    raise HTTPException(status_code=400, detail=f"Seat {requested_seat_id} not found on this airplane")
                normalized_class = SeatClass.BUSINESS if seat_obj.seat_class in [SeatClass.BUSINESS, SeatClass.FIRST] else SeatClass.ECONOMY
                if preferred_class and normalized_class != preferred_class:
                    raise HTTPException(status_code=400, detail=f"Seat {requested_seat_id} class mismatch")
                if requested_seat_id in taken_seat_ids or requested_seat_id in assigned_seats:
                    raise HTTPException(status_code=400, detail=f"Seat {requested_seat_id} is already taken")
                assigned_seats.append(requested_seat_id)
            else:
                chosen = None
                for seat in seat_templates:
                    normalized_class = SeatClass.BUSINESS if seat.seat_class in [SeatClass.BUSINESS, SeatClass.FIRST] else SeatClass.ECONOMY
                    if seat.id in taken_seat_ids or seat.id in assigned_seats:
                        continue
                    if preferred_class and normalized_class != preferred_class:
                        continue
                    chosen = seat.id
                    break
                if not chosen:
                    raise HTTPException(status_code=400, detail="No seats available that match requested class")
                assigned_seats.append(chosen)

        booking_ref = f"AIT-{uuid.uuid4().hex[:6].upper()}"
        total_price = flight.base_price * passengers_count

        try:
            booking = Booking(
                user_id=user_id,
                flight_id=flight_id,
                booking_reference=booking_ref,
                total_price=total_price,
                passengers_count=passengers_count,
                status=BookingStatus.PENDING,
                created_at=datetime.now()
            )
            self.session.add(booking)
            self.session.flush()

            for pax_data, seat_id_final in zip(passengers_payload, assigned_seats):
                ticket = Ticket(
                    booking_id=booking.id,
                    passenger_id=user_id,  # Владелец управляет группой
                    seat_id=seat_id_final,
                    passenger_first_name=pax_data.get("first_name"),
                    passenger_last_name=pax_data.get("last_name"),
                    passenger_phone=pax_data.get("phone"),
                    passenger_passport_number=pax_data.get("passport_number"),
                    passenger_nationality=pax_data.get("nationality"),
                    ticket_number=f"T-{uuid.uuid4().hex[:8].upper()}"
                )
                self.session.add(ticket)

            self.session.commit()
        except Exception:
            self.session.rollback()
            raise

        # Re-fetch with relationships using separate queries to avoid serialization issues
        result = self.session.get(Booking, booking.id)
        if result:
            # Загружаем flight и связанные объекты отдельными запросами
            result.flight = self.session.get(Flight, result.flight_id)
            if result.flight:
                result.flight.departure_airport = self.session.get(Airport, result.flight.departure_airport_id)
                result.flight.arrival_airport = self.session.get(Airport, result.flight.arrival_airport_id)
            # Загружаем tickets отдельным запросом
            result.tickets = list(self.session.exec(
                select(Ticket).where(Ticket.booking_id == result.id)
            ).all())
            result.user = self.session.get(User, result.user_id)
            print(f"DEBUG: Created booking result: {result}")
            print(f"DEBUG: Booking ID: {result.id}, Ref: {result.booking_reference}")
        
        # Send notification for booking creation
        self._send_booking_notification(result)
        
        return result
    
    def _send_booking_notification(self, booking: Booking):
        """Send notification when booking is created"""
        try:
            notification_service = NotificationService(self.session)
            notification_service.notify_booking_created(booking)
            print("DEBUG: Booking created notification sent via NotificationService")
        except Exception as e:
            print(f"Failed to send booking notification: {e}")

    def get_user_bookings(self, user_id: int):
        # Auto-cleanup expired bookings when user checks their list
        self.cleanup_expired_bookings()
        
        # Загружаем bookings базовым запросом
        bookings = list(self.session.exec(
            select(Booking).where(Booking.user_id == user_id)
        ).all())
        
        if not bookings:
            return []
        
        # Получаем все flight_id и booking_id
        flight_ids = [b.flight_id for b in bookings]
        booking_ids = [b.id for b in bookings]
        
        # Загружаем все flights одним запросом
        flights = {f.id: f for f in self.session.exec(
            select(Flight).where(Flight.id.in_(flight_ids))
        ).all()} if flight_ids else {}
        
        # Получаем все airport_id и airplane_id
        airport_ids = set()
        airplane_ids = set()
        for flight in flights.values():
            airport_ids.add(flight.departure_airport_id)
            airport_ids.add(flight.arrival_airport_id)
            airplane_ids.add(flight.airplane_id)
        
        # Загружаем все airports одним запросом
        airports = {a.id: a for a in self.session.exec(
            select(Airport).where(Airport.id.in_(airport_ids))
        ).all()} if airport_ids else {}
        
        # Загружаем все airplanes одним запросом
        airplanes = {a.id: a for a in self.session.exec(
            select(Airplane).where(Airplane.id.in_(airplane_ids))
        ).all()} if airplane_ids else {}
        
        # Загружаем все tickets одним запросом
        tickets_dict = {}
        if booking_ids:
            all_tickets = self.session.exec(
                select(Ticket).where(Ticket.booking_id.in_(booking_ids))
            ).all()
            for ticket in all_tickets:
                if ticket.booking_id not in tickets_dict:
                    tickets_dict[ticket.booking_id] = []
                tickets_dict[ticket.booking_id].append(ticket)
        
        # Вручную присваиваем связанные объекты
        for booking in bookings:
            # Присваиваем flight
            if booking.flight_id in flights:
                flight = flights[booking.flight_id]
                booking.flight = flight
                
                # Присваиваем airports и airplane к flight
                if flight.departure_airport_id in airports:
                    flight.departure_airport = airports[flight.departure_airport_id]
                if flight.arrival_airport_id in airports:
                    flight.arrival_airport = airports[flight.arrival_airport_id]
                if flight.airplane_id in airplanes:
                    flight.airplane = airplanes[flight.airplane_id]
            
            # Присваиваем tickets
            if booking.id in tickets_dict:
                booking.tickets = tickets_dict[booking.id]
            else:
                booking.tickets = []
        
        return bookings

    def cleanup_expired_bookings(self):
        """Cancel expired bookings and notify users"""
        ten_mins_ago = datetime.now() - timedelta(minutes=10)
        expired = self.session.exec(
            select(Booking).where(
                Booking.status == BookingStatus.PENDING,
                Booking.created_at < ten_mins_ago
            )
        ).all()
        
        for b in expired:
            b.status = BookingStatus.CANCELLED
            self.session.add(b)
            
            # Send expiration notification
            notification = Notification(
                user_id=b.user_id,
                notification_type=NotificationType.BOOKING_EXPIRED,
                title="Бронь истекла",
                message=f"Бронь {b.booking_reference} отменена из-за истечения времени оплаты.",
                booking_id=b.id,
                flight_id=b.flight_id,
                is_read=False,
                created_at=datetime.now()
            )
            self.session.add(notification)
            
        self.session.commit()
        return len(expired)

    # Назначение: Предполетная проверка группы билетов (checking)
    # Принимает: booking_id группы, текущего пользователя-владельца
    # Возвращает: результат проверки, QR по каждому билету, данные рейса и гейтов
    def perform_checking(self, booking_id: int, current_user: User):
        try:
            print(f"DEBUG perform_checking: booking_id={booking_id}, user_id={current_user.id}")
            # Загружаем booking базовым запросом
            booking = self.session.exec(
                select(Booking).where(Booking.id == booking_id)
            ).first()
            print(f"DEBUG: booking found: {booking is not None}")

            if not booking:
                print(f"DEBUG: booking not found")
                return {"success": False, "reason": "INVALID_TICKET"}
            
            if booking.user_id != current_user.id:
                print(f"DEBUG: user mismatch: booking.user_id={booking.user_id}, current_user.id={current_user.id}")
                return {"success": False, "reason": "INVALID_TICKET"}

            # Загружаем flight отдельным запросом
            print(f"DEBUG: loading flight_id={booking.flight_id}")
            flight = self.session.get(Flight, booking.flight_id)
            print(f"DEBUG: flight found: {flight is not None}")
            if not flight:
                print(f"DEBUG: flight not found")
                return {"success": False, "reason": "INVALID_TICKET"}

            now = datetime.now()
            print(f"DEBUG: now={now}, scheduled_departure={flight.scheduled_departure}, booking.status={booking.status}, flight.status={flight.status}")
            
            # Проверяем, что билет оплачен
            if booking.status == BookingStatus.CHECKED_IN:
                return {"success": False, "reason": "ALREADY_CHECKED_IN", "message": "Регистрация уже пройдена"}
            if booking.status != BookingStatus.PAID:
                return {"success": False, "reason": "UNPAID_TICKET"}
            
            # Проверяем, что рейс не отменен
            if flight.status == FlightStatus.CANCELLED:
                return {"success": False, "reason": "FLIGHT_CANCELLED"}
            
            scheduled_departure = flight.scheduled_departure
            
            # Проверяем, что рейс еще не вылетел
            if flight.status == FlightStatus.DEPARTED:
                return {"success": False, "reason": "ALREADY_DEPARTED"}
            if scheduled_departure and now >= scheduled_departure:
                return {"success": False, "reason": "ALREADY_DEPARTED"}
            
            # Check-in доступен только в диапазоне от 24 часов до рейса до 1 часа до рейса
            if scheduled_departure:
                time_until_departure = scheduled_departure - now
                
                # Проверяем, что до рейса осталось не более 24 часов
                if time_until_departure > timedelta(hours=24):
                    return {
                        "success": False, 
                        "reason": "CHECKIN_TOO_EARLY",
                        "message": "Check-in is available only 24 hours before the flight"
                    }
                
                # Проверяем, что до рейса осталось не менее 1 часа
                if time_until_departure < timedelta(hours=1):
                    return {
                        "success": False, 
                        "reason": "CHECKIN_TOO_LATE",
                        "message": "Check-in closes 1 hour before the flight"
                    }

            # Загружаем все tickets для этого booking отдельным запросом
            print(f"DEBUG: loading tickets for booking_id={booking_id}")
            tickets = list(self.session.exec(
                select(Ticket).where(Ticket.booking_id == booking_id)
            ).all())
            print(f"DEBUG: found {len(tickets)} tickets")

            if not tickets:
                print(f"DEBUG: no tickets found")
                return {"success": False, "reason": "INVALID_TICKET", "message": "Билеты не найдены"}

            # Получаем все seat_id из tickets
            seat_ids = [t.seat_id for t in tickets if t.seat_id]
            
            # Загружаем все seats одним запросом
            seats = {s.id: s for s in self.session.exec(
                select(SeatTemplate).where(SeatTemplate.id.in_(seat_ids))
            ).all()} if seat_ids else {}

            tickets_payload = []
            for ticket in tickets:
                seat = seats.get(ticket.seat_id) if ticket.seat_id else None
                seat_class = SeatClass.BUSINESS if seat and seat.seat_class in [SeatClass.BUSINESS, SeatClass.FIRST] else SeatClass.ECONOMY
                tickets_payload.append({
                    "ticket_id": ticket.id,
                    "ticket_number": ticket.ticket_number,
                    "qr": f"QR-{ticket.ticket_number}",
                    "seat": {
                        "row": seat.row_number if seat else None,
                        "letter": seat.seat_letter if seat else None
                    },
                    "class": seat_class.value,
                    "passenger_first_name": ticket.passenger_first_name,
                    "passenger_last_name": ticket.passenger_last_name,
                    "passenger_phone": ticket.passenger_phone,
                    "passenger_passport_number": ticket.passenger_passport_number,
                    "passenger_nationality": ticket.passenger_nationality
                })

            # Сериализуем datetime в ISO формат для JSON перед коммитом
            departure_str = None
            try:
                if scheduled_departure:
                    departure_str = scheduled_departure.isoformat()
            except Exception as e:
                print(f"Error serializing departure: {e}")
                departure_str = str(scheduled_departure) if scheduled_departure else None
            
            arrival_str = None
            if flight.scheduled_arrival:
                try:
                    scheduled_arrival = flight.scheduled_arrival
                    arrival_str = scheduled_arrival.isoformat()
                except Exception as e:
                    print(f"Error serializing arrival: {e}")
                    arrival_str = str(flight.scheduled_arrival)
            
            # Сохраняем данные для ответа перед коммитом
            result_data = {
                "success": True,
                "flight": {
                    "flight_number": flight.flight_number,
                    "departure": departure_str,
                    "arrival": arrival_str
                },
                "gate_departure": flight.gate_departure,
                "gate_arrival": flight.gate_arrival,
                "tickets": tickets_payload
            }
            
            # Обновляем статус и коммитим
            print(f"DEBUG: updating booking status to CHECKED_IN")
            booking.status = BookingStatus.CHECKED_IN
            self.session.add(booking)
            try:
                print(f"DEBUG: committing transaction")
                self.session.commit()
                print(f"DEBUG: transaction committed successfully")
            except Exception as commit_error:
                print(f"DEBUG: commit error: {commit_error}")
                self.session.rollback()
                raise HTTPException(status_code=500, detail=f"Failed to update booking status: {str(commit_error)}")
            
            return result_data
        except HTTPException:
            raise
        except Exception as e:
            print(f"Error in perform_checking: {e}")
            import traceback
            traceback.print_exc()
            raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

    # Назначение: Отменить бронирование, если до рейса больше 24 часов
    # Принимает: booking_id, текущего пользователя
    # Возвращает: результат отмены с освобождением мест
    def cancel_booking(self, booking_id: int, current_user: User):
        booking = self.session.get(Booking, booking_id)
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        
        # Проверяем владельца
        if booking.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only cancel your own bookings")
        
        # Проверяем статус бронирования
        if booking.status in [BookingStatus.CANCELLED, BookingStatus.REFUNDED]:
            raise HTTPException(status_code=400, detail="Booking is already cancelled")
        
        # Загружаем рейс
        flight = self.session.get(Flight, booking.flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        # Проверяем, что до рейса больше 24 часов
        now = datetime.now()
        scheduled_departure = flight.scheduled_departure
        
        time_until_departure = scheduled_departure - now
        if time_until_departure <= timedelta(hours=24):
            raise HTTPException(
                status_code=400, 
                detail="Cancellation is only allowed more than 24 hours before departure"
            )
        
        # Отменяем бронирование
        booking.status = BookingStatus.CANCELLED
        self.session.add(booking)
        
        # Освобождаем места (удаляем seat_id из билетов)
        tickets = self.session.exec(
            select(Ticket).where(Ticket.booking_id == booking_id)
        ).all()
        
        freed_seats = []
        for ticket in tickets:
            if ticket.seat_id:
                seat = self.session.get(SeatTemplate, ticket.seat_id)
                if seat:
                    freed_seats.append(f"{seat.row_number}{seat.seat_letter}")
                ticket.seat_id = None  # Освобождаем место
                self.session.add(ticket)
        
        self.session.commit()
        
        # Отправляем уведомление об отмене
        try:
            notification_service = NotificationService(self.session)
            notification = Notification(
                user_id=booking.user_id,
                notification_type=NotificationType.BOOKING_CANCELLED,
                title="Бронирование отменено",
                message=f"Ваше бронирование {booking.booking_reference} успешно отменено. Места {', '.join(freed_seats)} освобождены.",
                booking_id=booking.id,
                flight_id=booking.flight_id,
                is_read=False,
                created_at=datetime.now()
            )
            self.session.add(notification)
            self.session.commit()
        except Exception as e:
            print(f"Failed to send cancellation notification: {e}")
        
        return {
            "success": True,
            "message": f"Booking {booking.booking_reference} cancelled successfully",
            "freed_seats": freed_seats,
            "refund_amount": booking.total_price
        }

    # Назначение: Получить детали билета после check-in с QR-кодом и полной информацией
    # Принимает: booking_id, текущего пользователя
    # Возвращает: полную информацию о билете, рейсе, местах и QR-коды
    def get_ticket_details(self, booking_id: int, current_user: User):
        booking = self.session.get(Booking, booking_id)
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        
        # Проверяем владельца
        if booking.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only view your own ticket details")
        
        # Проверяем, что check-in пройден
        if booking.status != BookingStatus.CHECKED_IN:
            raise HTTPException(status_code=400, detail="Check-in must be completed to view ticket details")
        
        # Загружаем рейс с аэропортами
        flight = self.session.get(Flight, booking.flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        departure_airport = self.session.get(Airport, flight.departure_airport_id)
        arrival_airport = self.session.get(Airport, flight.arrival_airport_id)
        airplane = self.session.get(Airplane, flight.airplane_id)
        
        # Загружаем билеты с местами
        tickets = list(self.session.exec(
            select(Ticket).where(Ticket.booking_id == booking_id)
        ).all())
        
        # Получаем информацию о местах
        seat_ids = [t.seat_id for t in tickets if t.seat_id]
        seats = {s.id: s for s in self.session.exec(
            select(SeatTemplate).where(SeatTemplate.id.in_(seat_ids))
        ).all()} if seat_ids else {}
        
        # Формируем детали билетов
        ticket_details = []
        for ticket in tickets:
            seat = seats.get(ticket.seat_id) if ticket.seat_id else None
            seat_class = SeatClass.BUSINESS if seat and seat.seat_class in [SeatClass.BUSINESS, SeatClass.FIRST] else SeatClass.ECONOMY
            
            ticket_data = {
                "ticket_number": ticket.ticket_number,
                "passenger_name": f"{ticket.passenger_first_name} {ticket.passenger_last_name}",
                "passenger_phone": ticket.passenger_phone,
                "passenger_passport_number": ticket.passenger_passport_number,
                "passenger_nationality": ticket.passenger_nationality,
                "seat": {
                    "row": seat.row_number if seat else None,
                    "letter": seat.seat_letter if seat else None,
                    "class": seat_class.value
                },
                "qr_code": f"QR-{ticket.ticket_number}",
                "boarding_pass": f"BP-{ticket.ticket_number}"
            }
            # Отладочный вывод
            print(f"DEBUG get_ticket_details: Ticket {ticket.ticket_number}")
            print(f"  Phone: {ticket.passenger_phone}")
            print(f"  Passport: {ticket.passenger_passport_number}")
            print(f"  Nationality: {ticket.passenger_nationality}")
            ticket_details.append(ticket_data)
        
        # Формируем полную информацию о рейсе
        scheduled_departure = flight.scheduled_departure
        scheduled_arrival = flight.scheduled_arrival
        
        return {
            "booking_reference": booking.booking_reference,
            "status": booking.status.value,
            "total_price": booking.total_price,
            "passengers_count": booking.passengers_count,
            "flight": {
                "flight_number": flight.flight_number,
                "scheduled_departure": scheduled_departure.isoformat() if scheduled_departure else None,
                "scheduled_arrival": scheduled_arrival.isoformat() if scheduled_arrival else None,
                "status": flight.status.value,
                "gate_departure": flight.gate_departure,
                "gate_arrival": flight.gate_arrival,
                "departure_airport": {
                    "code": departure_airport.code if departure_airport else None,
                    "name": departure_airport.name if departure_airport else None,
                    "city": departure_airport.city if departure_airport else None,
                    "country": departure_airport.country if departure_airport else None
                },
                "arrival_airport": {
                    "code": arrival_airport.code if arrival_airport else None,
                    "name": arrival_airport.name if arrival_airport else None,
                    "city": arrival_airport.city if arrival_airport else None,
                    "country": arrival_airport.country if arrival_airport else None
                },
                "airplane": {
                    "model": airplane.model if airplane else None,
                    "registration": airplane.registration if airplane else None
                }
            },
            "tickets": ticket_details,
            "check_in_completed": True,
            "boarding_time": (scheduled_departure - timedelta(minutes=30)).isoformat() if scheduled_departure else None
        }

    def reassign_passenger_seat(self, ticket_id: int, new_seat_id: int, user: User):
        """Reassign a passenger to a different seat (staff only)"""
        ticket = self.session.get(Ticket, ticket_id)
        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")
        
        booking = self.session.get(Booking, ticket.booking_id)
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        
        flight = self.session.get(Flight, booking.flight_id)
        if not flight:
            raise HTTPException(status_code=404, detail="Flight not found")
        
        # Cannot reassign seats for cancelled or finished flights
        if flight.status == FlightStatus.CANCELLED:
            raise HTTPException(status_code=400, detail="Cannot reassign seats for cancelled flights")
        
        if flight.status == FlightStatus.FINISHED:
            raise HTTPException(status_code=400, detail="Cannot reassign seats for finished flights")
        
        # Only staff/admin can reassign seats
        if user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise HTTPException(status_code=403, detail="Only staff can reassign seats")
        
        if user.role == UserRole.STAFF and flight.owner_id != user.id:
            raise HTTPException(status_code=403, detail="You can only reassign seats for your own flights")
        
        # Check if new seat exists and is on the same airplane
        new_seat = self.session.get(SeatTemplate, new_seat_id)
        if not new_seat:
            raise HTTPException(status_code=404, detail="New seat not found")
        
        if new_seat.airplane_id != flight.airplane_id:
            raise HTTPException(status_code=400, detail="New seat must be on the same airplane")
        
        # Check if new seat is available
        # We need to check if any other ticket (from active bookings) has this seat
        # Only check tickets from paid or checked_in bookings for this flight
        # Get all bookings for this flight with active status
        active_bookings = self.session.exec(
            select(Booking).where(
                Booking.flight_id == flight.id,
                Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
            )
        ).all()
        
        active_booking_ids = [b.id for b in active_bookings]
        
        # Check if any ticket (except the current one) from active bookings has this seat
        if active_booking_ids:
            existing_ticket = self.session.exec(
                select(Ticket).where(
                    Ticket.seat_id == new_seat_id,
                    Ticket.id != ticket_id,
                    Ticket.booking_id.in_(active_booking_ids)
                )
            ).first()
            
            if existing_ticket:
                raise HTTPException(status_code=400, detail="New seat is already taken")
        
        # Also check if the passenger is trying to move to the same seat they already have
        if ticket.seat_id == new_seat_id:
            raise HTTPException(status_code=400, detail="Passenger is already assigned to this seat")
        
        # Get old seat info for notification
        old_seat = None
        if ticket.seat_id:
            old_seat = self.session.get(SeatTemplate, ticket.seat_id)
        
        # Reassign seat
        old_seat_info = f"{old_seat.row_number}{old_seat.seat_letter}" if old_seat else "unassigned"
        new_seat_info = f"{new_seat.row_number}{new_seat.seat_letter}"
        
        ticket.seat_id = new_seat_id
        self.session.add(ticket)
        self.session.commit()
        
        # Send notification to passenger
        try:
            notification_service = NotificationService(self.session)
            notification_service.create_notification(
                user_id=booking.user_id,
                notification_type=NotificationType.FLIGHT_UPDATE,
                title="Seat Reassignment",
                message=f"Your seat for flight {flight.flight_number} has been changed from {old_seat_info} to {new_seat_info}.",
                booking_id=booking.id,
                flight_id=flight.id
            )
        except Exception as e:
            print(f"Error sending seat reassignment notification: {e}")
        
        return {
            "ticket_id": ticket.id,
            "ticket_number": ticket.ticket_number,
            "old_seat": old_seat_info,
            "new_seat": new_seat_info,
            "message": "Seat reassigned successfully"
        }

class PaymentService:
    def __init__(self, session: Session):
        self.session = session

    # Назначение: Обрабатывает оплату, требуя видимые поля карты и владельца бронирования
    # Принимает: booking_id, данные карты, текущего пользователя
    # Возвращает: статус оплаты
    def process_dummy_payment(self, booking_id: int, card_data: dict, current_user: User):
        print(f"DEBUG: Processing payment for booking_id: {booking_id}")
        # Ensure booking_id is an int
        try:
            booking_id = int(booking_id)
        except (ValueError, TypeError):
            print(f"DEBUG: Invalid booking_id type: {type(booking_id)}")
            raise HTTPException(status_code=400, detail="Invalid booking ID")

        # Fake payment logic
        booking = self.session.get(Booking, booking_id)
        if not booking:
            print(f"DEBUG: Booking {booking_id} not found")
            raise HTTPException(status_code=404, detail="Booking not found")
        if booking.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only pay your own bookings")
            
        print(f"DEBUG: Booking found, status: {booking.status}")
        if booking.status == BookingStatus.PAID:
            return {"status": "already_paid", "message": "Booking is already paid"}
            
        # Check expiry
        now = datetime.now()
        created_at = booking.created_at
        
        ten_mins_ago = now - timedelta(minutes=10)
        
        if created_at < ten_mins_ago and booking.status == BookingStatus.PENDING:
            print(f"DEBUG: Booking {booking_id} expired")
            booking.status = BookingStatus.CANCELLED
            self.session.add(booking)
            self.session.commit()
            raise HTTPException(status_code=400, detail="Payment failed: Booking expired")

        # In a real app, you'd validate card_number, exp, cvv here
        # For dummy payment, we just succeed
        booking.status = BookingStatus.PAID
        self.session.add(booking)
        self.session.commit()
        self.session.refresh(booking)
        
        # Send payment success notification
        self._send_payment_notification(booking)
        
        print(f"DEBUG: Payment successful for booking {booking_id}")
        return {"status": "success", "message": "Payment successful", "booking_id": booking.id}
    
    def _send_payment_notification(self, booking: Booking):
        """Send notification when payment is successful"""
        try:
            notification_service = NotificationService(self.session)
            notification_service.notify_booking_paid(booking)
            print("DEBUG: Payment notification sent via NotificationService")
        except Exception as e:
            print(f"Failed to send payment notification: {e}")

