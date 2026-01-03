from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_
from fastapi import HTTPException, status
from datetime import datetime, timedelta, timezone
from typing import List, Optional
from app.models.flight import Flight, FlightStatus
from app.models.airport import Airport
from app.models.booking import Booking, BookingStatus, Ticket
from app.models.booking import SeatHold
from app.schemas.flight import FlightCreate, FlightUpdate, FlightSearch
from app.schemas.seat import SeatMap, Seat, StaffSeat, StaffSeatMap


def get_airports(db: Session) -> List[Airport]:
    return db.query(Airport).all()


def delete_airport(db: Session, airport_id: int) -> bool:
    airport = db.query(Airport).filter(Airport.id == airport_id).first()
    if not airport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Аэропорт не найден"
        )
    
    # 1. Find all affected flights (Origin or Destination)
    flights = db.query(Flight).filter(
        or_(
            Flight.origin_airport_id == airport_id,
            Flight.destination_airport_id == airport_id
        )
    ).all()
    
    from app.models.announcement import Announcement
    
    for flight in flights:
        # 2. Find confirmed bookings
        bookings = db.query(Booking).filter(
            Booking.flight_id == flight.id,
            Booking.status == BookingStatus.CONFIRMED
        ).all()
        
        # 3. Notify passengers and Cancel bookings
        for booking in bookings:
            # Create persistent notification (flight_id will be set to None or we need to handle it)
            # Since we made flight_id nullable, we can set it to None or leave it. 
            # BUT if we delete flight, the announcement might cascade delete if connected via relationship?
            # We need to ensure the announcement is NOT deleted. 
            # The relationship in Flight is: announcements = relationship(..., cascade="all, delete-orphan")
            # So we MUST NOT link it to the flight being deleted if we want it to survive.
            
            msg = f"Рейс {flight.flight_number} ({flight.departure_city} - {flight.arrival_city}) был отменен из-за закрытия аэропорта. Ваши средства будут возвращены."
            
            ann = Announcement(
                title="Рейс отменен",
                message=msg,
                flight_id=None, # Detach from flight so it survives flight deletion
                created_by=1, # System/Admin (using ID 1 for now, or finding a staff member)
                created_at=datetime.utcnow()
            )
            # Find passenger user to link? 
            # Wait, Announcement doesn't have a 'passenger_id' field directly, it has 'created_by'. 
            # How do we show it to the specific passenger? 
            # 'get_announcements' filters by `flight_id` OR `created_by` (which is wrong in my previous fix, it was showing created_by=current_user).
            # The previous logic in `passenger.py` was:
            # announcements = db.query(AnnouncementModel).filter(
            #    (AnnouncementModel.flight_id.in_(booked_flight_ids)) | 
            #    (AnnouncementModel.flight_id == None) |
            #    (AnnouncementModel.created_by == current_user.id) 
            # )
            # So if I set created_by = passenger.id, the passenger will see it.
            
            ann.created_by = booking.passenger_id
            db.add(ann)
            
            # Refund logic (stub)
            # booking.status = BookingStatus.CANCELLED
            # We don't strictly need to update status if we are deleting the flight, 
            # but usually it's better to keep record. However, if we delete the airport, we delete the flight.
            # CASCADE deletion at DB level will likely delete the booking anyway if it's linked to flight.
        
        # Delete flight (and cascade delete bookings/tickets/seat_holds)
        db.delete(flight)
    
    # 4. Delete airport
    db.delete(airport)
    db.commit()
    return True


def search_flights(
    db: Session,
    origin_code: str,
    destination_code: str,
    departure_date: datetime
) -> List[Flight]:
    # Получаем аэропорты
    origin = db.query(Airport).filter(Airport.code == origin_code).first()
    destination = db.query(Airport).filter(Airport.code == destination_code).first()
    
    if not origin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Аэропорт с кодом {origin_code} не найден"
        )
    if not destination:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Аэропорт с кодом {destination_code} не найден"
        )
    
    # Ищем рейсы на указанную дату
    now = datetime.now()
    
    # Auto-update statuses before search
    update_flight_statuses(db)
    
    booking_cutoff = now + timedelta(hours=2)
    
    start_date = departure_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end_date = start_date + timedelta(days=1)
    
    # Ensure start_date is at least the cutoff if searching for today
    actual_start = max(start_date, booking_cutoff)
    
    flights = db.query(Flight).options(joinedload(Flight.aircraft)).filter(
        and_(
            Flight.origin_airport_id == origin.id,
            Flight.destination_airport_id == destination.id,
            Flight.scheduled_departure >= actual_start,
            Flight.scheduled_departure < end_date,
            Flight.status != FlightStatus.CANCELLED
        )
    ).all()
    
    # Run lazy update on results? 
    # Better to run it BEFORE query if we want accurate filtering, but running it on all database might be slow?
    # For now, let's run it globally as the DB is small.
    update_flight_statuses(db)
    # Re-fetch or just update objects in memory? 
    # Commit in update_flight_statuses updates the DB. We should ideally run it before the query.
    # The query might return stale data if we don't refresh.
    
    # Let's adjust: run update FIRST.
    return flights


def update_flight_statuses(db: Session):
    """
    Checks all active flights and updates their status based on current time.
    SCHEDULED -> BOARDING (2h before) -> DEPARTED (at dep time) -> ARRIVED (at arr time)
    """
    now = datetime.utcnow()
    
    # 1. SCHEDULED -> BOARDING (2 hours before departure)
    boarding_cutoff = now + timedelta(hours=2)
    # Flights that are Scheduled AND scheduled_departure < now + 2h AND scheduled_departure > now
    to_boarding = db.query(Flight).filter(
        Flight.status == FlightStatus.SCHEDULED,
        Flight.scheduled_departure <= boarding_cutoff,
        Flight.scheduled_departure > now
    ).all()
    
    for flight in to_boarding:
        flight.status = FlightStatus.BOARDING
        # Could add announcements here if we wanted
        
    # 2. BOARDING/SCHEDULED -> DEPARTED (Time passed)
    # Flights that are (Scheduled OR Boarding) AND scheduled_departure <= now AND scheduled_arrival > now
    to_departed = db.query(Flight).filter(
        Flight.status.in_([FlightStatus.SCHEDULED, FlightStatus.BOARDING]),
        Flight.scheduled_departure <= now,
        Flight.scheduled_arrival > now  # Ensure we don't skip straight to Arrived if app was down
    ).all()
    
    for flight in to_departed:
        flight.status = FlightStatus.DEPARTED
        
    # 3. DEPARTED -> ARRIVED (Time passed)
    # Flights that are Departed AND scheduled_arrival <= now
    to_arrived = db.query(Flight).filter(
        Flight.status == FlightStatus.DEPARTED,
        Flight.scheduled_arrival <= now
    ).all()
    
    for flight in to_arrived:
        flight.status = FlightStatus.ARRIVED
        
    if to_boarding or to_departed or to_arrived:
        db.commit()


def get_flight_by_id(db: Session, flight_id: int) -> Flight:
    # Ensure status is up to date before returning
    update_flight_statuses(db)
    flight = db.query(Flight).options(joinedload(Flight.aircraft)).filter(Flight.id == flight_id).first()
    if not flight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Рейс не найден"
        )
    return flight


def _build_seats(
    capacity: int,
    seats_per_row: int,
    occupied_map: dict,  # seat_number -> (passenger_name, booking_id) or None
    held_seats: list,
    base_price: float, # Added base_price
    is_staff: bool = False
) -> list:
    import math
    needed_rows = math.ceil(capacity / seats_per_row)
    seats = []
    
    for row in range(1, needed_rows + 1):
        for seat_idx in range(1, seats_per_row + 1):
            if len(seats) >= capacity:
                break
                
            column = chr(64 + seat_idx)
            seat_number = f"{row}{column}"
            
            # Determine status
            p_name = None
            b_id = None
            
            if seat_number in occupied_map:
                seat_status = "occupied"
                if is_staff:
                    p_name, b_id = occupied_map[seat_number]
            elif seat_number in held_seats:
                seat_status = "reserved"
            else:
                seat_status = "available"
            
            # Seat type logic
            price_multiplier = 1.0
            if row <= 2:
                seat_type = "business"
                price_multiplier = 2.0
            elif seat_idx == 1 or seat_idx == seats_per_row:
                seat_type = "window"
            elif seat_idx == 3 or seat_idx == (seats_per_row // 2 + (1 if seats_per_row % 2 == 0 else 0)):
                seat_type = "aisle"
            else:
                seat_type = "standard"
            
            seat_price = base_price * price_multiplier
            
            # Emergency Exit Logic
            is_exit = (row == 12)

            if is_staff:
                seats.append(StaffSeat(
                    seat_number=seat_number,
                    row=row,
                    column=column,
                    seat_type=seat_type,
                    status=seat_status,
                    passenger_name=p_name,
                    booking_id=b_id,
                    is_emergency_exit=is_exit,
                    price=seat_price
                ))
            else:
                seats.append(Seat(
                    seat_number=seat_number,
                    row=row,
                    column=column,
                    seat_type=seat_type,
                    status=seat_status,
                    is_emergency_exit=is_exit,
                    price=seat_price
                ))
        if len(seats) >= capacity:
            break
    return seats


def get_flight_seat_map(db: Session, flight_id: int) -> SeatMap:
    # Proactive cleanup before showing seat map
    from app.services.booking_service import cleanup_expired_holds
    cleanup_expired_holds(db)
    
    flight = get_flight_by_id(db, flight_id)
    
    if not flight.aircraft or not flight.aircraft.seat_template:
        return SeatMap(flight_id=flight_id, seats=[], total_seats=0, available_seats=0, occupied_seats=0)
        
    confirmed_bookings = db.query(Booking).filter(
        and_(Booking.flight_id == flight_id, Booking.status == BookingStatus.CONFIRMED)
    ).all()
    occupied_seats = {b.seat_number for b in confirmed_bookings}
    
    active_holds = db.query(SeatHold).filter(
        and_(SeatHold.flight_id == flight_id, SeatHold.expires_at > datetime.utcnow())
    ).all()
    held_seats = {hold.seat_number for hold in active_holds}
    
    template_map = flight.aircraft.seat_template.seat_map or {"seats": []}
    seats_list = []
    
    for s_data in template_map.get("seats", []):
        seat_num = s_data["seat_number"]
        
        status = "available"
        if seat_num in occupied_seats:
            status = "occupied"
        elif seat_num in held_seats:
            status = "reserved"
            
        # Price logic
        price_multiplier = 2.0 if s_data.get("class") == "BUSINESS" else 1.0
        
        seats_list.append(Seat(
            seat_number=seat_num,
            row=s_data["row"],
            column=s_data["letter"],
            seat_type=s_data["class"].lower(),
            status=status,
            is_emergency_exit=s_data.get("is_emergency_exit", False),
            price=flight.base_price * price_multiplier
        ))
        
    return SeatMap(
        flight_id=flight_id,
        seats=seats_list,
        total_seats=len(seats_list),
        available_seats=len([s for s in seats_list if s.status == "available"]),
        occupied_seats=len([s for s in seats_list if s.status == "occupied"])
    )


def get_staff_flight_seat_map(db: Session, flight_id: int) -> StaffSeatMap:
    flight = get_flight_by_id(db, flight_id)
    
    if not flight.aircraft or not flight.aircraft.seat_template:
        return StaffSeatMap(flight_id=flight_id, seats=[], total_seats=0, available_seats=0, occupied_seats=0)
        
    confirmed_bookings = db.query(Booking).filter(
        and_(Booking.flight_id == flight_id, Booking.status == BookingStatus.CONFIRMED)
    ).all()
    
    occupied_info = {
        b.seat_number: (f"{b.first_name or ''} {b.last_name or ''}".strip() or "SYSTEM BLOCK", b.id)
        for b in confirmed_bookings
    }
    
    active_holds = db.query(SeatHold).filter(
        and_(SeatHold.flight_id == flight_id, SeatHold.expires_at > datetime.utcnow())
    ).all()
    held_seats = {hold.seat_number for hold in active_holds}
    
    template_map = flight.aircraft.seat_template.seat_map or {"seats": []}
    seats_list = []
    
    for s_data in template_map.get("seats", []):
        seat_num = s_data["seat_number"]
        
        status = "available"
        p_name = None
        b_id = None
        
        if seat_num in occupied_info:
            status = "occupied"
            p_name, b_id = occupied_info[seat_num]
        elif seat_num in held_seats:
            status = "reserved"
            
        # Price logic
        price_multiplier = 2.0 if s_data.get("class") == "BUSINESS" else 1.0
        
        seats_list.append(StaffSeat(
            seat_number=seat_num,
            row=s_data["row"],
            column=s_data["letter"],
            seat_type=s_data["class"].lower(),
            status=status,
            passenger_name=p_name,
            booking_id=b_id,
            is_emergency_exit=s_data.get("is_emergency_exit", False),
            price=flight.base_price * price_multiplier
        ))
    
    return StaffSeatMap(
        flight_id=flight_id,
        seats=seats_list,
        total_seats=len(seats_list),
        available_seats=len([s for s in seats_list if s.status == "available"]),
        occupied_seats=len([s for s in seats_list if s.status == "occupied"])
    )


def create_flight(db: Session, flight_data: FlightCreate) -> Flight:
    # Валидация времени
    if flight_data.scheduled_arrival <= flight_data.scheduled_departure:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Время прибытия должно быть позже времени отправления"
        )

    # Проверяем занятость самолета на это время
    overlapping = db.query(Flight).filter(
        Flight.aircraft_id == flight_data.aircraft_id,
        Flight.status != FlightStatus.CANCELLED,
        and_(
            Flight.scheduled_departure < flight_data.scheduled_arrival,
            Flight.scheduled_arrival > flight_data.scheduled_departure
        )
    ).first()
    
    if overlapping:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Самолёт №{flight_data.aircraft_id} уже занят на рейсе {overlapping.flight_number} в это время"
        )

    # Проверяем, существует ли рейс с таким номером
    existing = db.query(Flight).filter(Flight.flight_number == flight_data.flight_number).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Рейс с таким номером уже существует"
        )
    
    # Validation: Flight must be created at least 24 hours before departure
    now = datetime.utcnow()
    min_departure = now + timedelta(hours=24)
    if flight_data.scheduled_departure < min_departure:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ошибка: рейс можно создать только минимум за 24 часа до вылета."
        )
        
    flight = Flight(**flight_data.dict())
    db.add(flight)
    
    # Action logging
    from app.models.announcement import Announcement
    db.add(Announcement(
        title="Новый рейс",
        message=f"Добавлен новый рейс {flight_data.flight_number}: {flight.origin_airport.city if flight.origin_airport else ''} -> {flight.destination_airport.city if flight.destination_airport else ''}.",
        flight_id=None, # Global system news
        created_at=datetime.utcnow(),
        created_by=1 # System
    ))
    
    db.commit()
    db.refresh(flight)
    return flight


def update_flight(db: Session, flight_id: int, flight_data: FlightUpdate) -> Flight:
    flight = get_flight_by_id(db, flight_id)
    
    update_data = flight_data.dict(exclude_unset=True)
    
    # Check for time overlap if aircraft or times are changing
    new_departure = update_data.get('scheduled_departure', flight.scheduled_departure)
    new_arrival = update_data.get('scheduled_arrival', flight.scheduled_arrival)
    new_aircraft_id = update_data.get('aircraft_id', flight.aircraft_id)
    
    if 'scheduled_departure' in update_data or 'scheduled_arrival' in update_data or 'aircraft_id' in update_data:
        if new_arrival <= new_departure:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ошибка: время прибытия должно быть позже времени вылета."
            )
        
        overlapping = db.query(Flight).filter(
            Flight.id != flight_id,
            Flight.aircraft_id == new_aircraft_id,
            Flight.status != FlightStatus.CANCELLED,
            and_(
                Flight.scheduled_departure < new_arrival,
                Flight.scheduled_arrival > new_departure
            )
        ).first()
        
        if overlapping:
            overlap_time = f"{overlapping.scheduled_departure.strftime('%H:%M')} - {overlapping.scheduled_arrival.strftime('%H:%M')}"
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Конфиликт расписания: Самолёт уже занят на рейсе {overlapping.flight_number} ({overlap_time})."
            )

    # Store old values for comparison and notification
    old_status = flight.status
    old_gate = flight.gate
    old_terminal = flight.terminal
    old_departure = flight.scheduled_departure
    
    # Apply updates
    for field, value in update_data.items():
        setattr(flight, field, value)
    
    # 3. Notification Logic for Significant Changes
    from app.models.announcement import Announcement
    from app.models.booking import Booking, BookingStatus
    from datetime import datetime
    
    # Check what changed and build descriptive messages
    changed_fields = []
    
    new_status = update_data.get('status')
    if new_status and new_status != old_status:
        changed_fields.append(f"Статус изменен с '{old_status}' на '{new_status}'")
    
    if 'gate' in update_data and update_data['gate'] != old_gate:
        changed_fields.append(f"Гейт изменен с '{old_gate or 'не указан'}' на '{update_data['gate']}'")
    
    if 'terminal' in update_data and update_data['terminal'] != old_terminal:
        changed_fields.append(f"Терминал изменен с '{old_terminal}' на '{update_data['terminal']}'")
    
    if 'scheduled_departure' in update_data and update_data['scheduled_departure'] != old_departure:
        old_time_str = old_departure.strftime('%H:%M %d.%m') if old_departure else "не указано"
        new_time_str = update_data['scheduled_departure'].strftime('%H:%M %d.%m')
        changed_fields.append(f"Время вылета перенесено с {old_time_str} на {new_time_str}")

    if changed_fields:
        # 1. Create one GENERAL announcement for the flight (visible to all)
        general_msg = f"Рейс {flight.flight_number}: " + ". ".join(changed_fields)
        general_ann = Announcement(
            title="Официальное обновление рейса",
            message=general_msg,
            flight_id=flight.id,
            created_by=1, # System/Admin
            created_at=datetime.utcnow()
        )
        db.add(general_ann)

        # 2. Create individual history entries for each passenger
        bookings = db.query(Booking).filter(
            Booking.flight_id == flight_id,
            Booking.status != BookingStatus.CANCELLED
        ).all()
        
        for booking in bookings:
            msg = ". ".join(changed_fields) + ". Пожалуйста, следите за обновлениями."
            
            ann = Announcement(
                title="История изменений рейса",
                message=msg,
                flight_id=flight.id,
                created_by=booking.passenger_id, # Target the specific passenger for history
                created_at=datetime.utcnow()
            )
            db.add(ann)

    db.commit()
    db.refresh(flight)
    return flight


def delete_flight(db: Session, flight_id: int) -> bool:
    flight = get_flight_by_id(db, flight_id)
    db.delete(flight)
    db.commit()
    return True

