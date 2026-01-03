from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from app.models.booking import SeatHold
from app.models.flight import Flight
from app.models.airplane import Airplane, SeatTemplate
from typing import List, Dict, Any
import re


def generate_seat_map(seat_template: SeatTemplate) -> List[str]:
    """Generate list of all seat numbers for a template"""
    seats = []
    for row in range(1, seat_template.rows + 1):
        for label in seat_template.seat_labels:
            seats.append(f"{row}{label}")
    return seats


def get_seat_category(seat_number: str, seat_template: SeatTemplate) -> str:
    """Get category for a seat based on template rules"""
    # Extract row number
    match = re.match(r'(\d+)', seat_number)
    if not match:
        return "STANDARD"
    
    row = int(match.group(1))
    
    # Check categories
    for range_str, category in seat_template.seat_categories.items():
        if '-' in range_str:
            start, end = map(int, range_str.split('-'))
            if start <= row <= end:
                return category
    
    return "STANDARD"


def get_available_seats(
    db: Session,
    flight_id: int,
    include_held: bool = False,
    include_passenger_info: bool = False
) -> Dict[str, Dict[str, Any]]:
    """Get seat map with availability status"""
    flight = db.query(Flight).filter(Flight.id == flight_id).first()
    if not flight:
        return {}
    
    airplane = db.query(Airplane).filter(Airplane.id == flight.airplane_id).first()
    if not airplane:
        return {}
    
    seat_template = db.query(SeatTemplate).filter(SeatTemplate.id == airplane.seat_template_id).first()
    if not seat_template:
        return {}
    
    # Build seat map and template info
    import json
    import string
    
    all_seats = []
    seat_to_category = {}
    custom_template = None
    
    # Priority 1: Fixed Airplane Layout (The NEW standard)
    if seat_template.class_layouts:
        class_layouts = seat_template.class_layouts
        if isinstance(class_layouts, str):
            try:
                class_layouts = json.loads(class_layouts)
            except:
                class_layouts = None

        if class_layouts:
            current_row = 1
            max_seats_per_row = 0
            
            def get_labels(count):
                return [string.ascii_uppercase[i] for i in range(count)]
            
            categories_order = ["BUSINESS", "EXTRA_LEGROOM", "ECONOMY"]
            
            for cat in categories_order:
                if cat in class_layouts:
                    rows = int(class_layouts[cat].get("rows", 0))
                    spr = int(class_layouts[cat].get("seats_per_row", 0))
                    if spr > max_seats_per_row:
                        max_seats_per_row = spr
                    
                    labels = get_labels(spr)
                    for r in range(rows):
                        row_num = current_row + r
                        for label in labels:
                            seat_num = f"{row_num}{label}"
                            all_seats.append(seat_num)
                            seat_to_category[seat_num] = cat
                    current_row += rows
            
            total_rows = current_row - 1
            final_labels = get_labels(max_seats_per_row)
            
            custom_template = {
                "id": seat_template.id,
                "name": f"{seat_template.name} (Fixed)",
                "rows": total_rows,
                "seats_per_row": max_seats_per_row,
                "seat_labels": final_labels,
                "aisle_positions": [max_seats_per_row // 2] if max_seats_per_row > 0 else [],
                "emergency_exits": seat_template.emergency_exits or [],
                "seat_categories": {} # Determined by seat_to_category
            }

    # Priority 2: Flight-specific allocations (LEGACY/BACKWARD COMPAT)
    if not custom_template and flight.category_allocations:
        try:
            allocs = flight.category_allocations
            if isinstance(allocs, str):
                allocs = json.loads(allocs)
            
            is_new_structure = any(isinstance(v, dict) and 'rows' in v for v in allocs.values())
            if is_new_structure:
                current_row = 1
                max_seats_per_row = 0
                
                def get_labels(count):
                    return [string.ascii_uppercase[i] for i in range(count)]
                
                categories_order = ["BUSINESS", "EXTRA_LEGROOM", "ECONOMY"]
                
                for cat in categories_order:
                    if cat in allocs:
                        rows = int(allocs[cat].get("rows", 0))
                        spr = int(allocs[cat].get("seats_per_row", 0))
                        if spr > max_seats_per_row:
                            max_seats_per_row = spr
                        
                        labels = get_labels(spr)
                        for r in range(rows):
                            row_num = current_row + r
                            for label in labels:
                                seat_num = f"{row_num}{label}"
                                all_seats.append(seat_num)
                                seat_to_category[seat_num] = cat
                        current_row += rows
                
                total_rows = current_row - 1
                final_labels = get_labels(max_seats_per_row)
                
                custom_template = {
                    "rows": total_rows,
                    "seats_per_row": max_seats_per_row,
                    "seat_labels": final_labels,
                    "aisle_positions": [max_seats_per_row // 2] if max_seats_per_row > 0 else [],
                    "emergency_exits": [],
                    "seat_categories": {}
                }
        except (json.JSONDecodeError, TypeError, ValueError):
            pass

    # Default: Use SeatTemplate directly
    if not custom_template:
        all_seats = generate_seat_map(seat_template)
        custom_template = {
            "rows": seat_template.rows,
            "seats_per_row": seat_template.seats_per_row,
            "seat_labels": seat_template.seat_labels,
            "aisle_positions": seat_template.aisle_positions,
            "emergency_exits": seat_template.emergency_exits,
            "seat_categories": seat_template.seat_categories
        }

    seat_map = {}
    
    # Get booked seats (from tickets)
    from app.models.booking import Ticket, Booking, BookingStatus
    
    booked_tickets = db.query(Ticket).join(Booking).filter(
        Booking.flight_id == flight_id,
        Ticket.seat_number.isnot(None),
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.HOLD])
    ).all()
    
    booked_seats_info = {
        ticket.seat_number: {
            "passenger_name": ticket.passenger_name,
            "pnr": ticket.booking.pnr,
            "is_checked_in": ticket.is_checked_in,
            "ticket_id": ticket.id
        }
        for ticket in booked_tickets
    }
    booked_seats = set(booked_seats_info.keys())
    
    # Get held seats
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    held_seats = {
        hold.seat_number
        for hold in db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.held_until > now
        )
    }
    
    # Build seat map
    for seat in all_seats:
        is_booked = seat in booked_seats
        is_held = seat in held_seats
        
        # Determine category
        if seat_to_category:
            category = seat_to_category.get(seat, "STANDARD")
        elif flight.category_allocations:
            try:
                # Fallback to old sequential logic if it's the old structure
                cat_allocs = flight.category_allocations
                if isinstance(cat_allocs, str):
                    cat_allocs = json.loads(cat_allocs)
                
                biz_count = int(cat_allocs.get("BUSINESS", 0))
                extra_count = int(cat_allocs.get("EXTRA_LEGROOM", 0))
                
                seat_index = all_seats.index(seat)
                if seat_index < biz_count:
                    category = "BUSINESS"
                elif seat_index < (biz_count + extra_count):
                    category = "EXTRA_LEGROOM"
                else:
                    category = "STANDARD"
            except (json.JSONDecodeError, TypeError, ValueError):
                category = get_seat_category(seat, seat_template)
        else:
            category = get_seat_category(seat, seat_template)

        # Calculate price based on category
        seat_price = flight.price
        if flight.category_prices:
            try:
                cat_prices = flight.category_prices
                if isinstance(cat_prices, str):
                    cat_prices = json.loads(cat_prices)
                
                if category in cat_prices:
                    seat_price = float(cat_prices[category])
            except (json.JSONDecodeError, TypeError, ValueError):
                pass

        seat_map[seat] = {
            "available": not (is_booked or (is_held and not include_held)),
            "category": category,
            "price": seat_price,
            "held_until": None,
            "passenger_info": booked_seats_info.get(seat) if is_booked and include_passenger_info else None
        }
        
        if is_held and include_held:
            hold = db.query(SeatHold).filter(
                SeatHold.flight_id == flight_id,
                SeatHold.seat_number == seat,
                SeatHold.held_until > now
            ).first()
            if hold:
                seat_map[seat]["held_until"] = hold.held_until.isoformat()
    
    return {
        "seat_map": seat_map,
        "template": custom_template
    }


def hold_seats(
    db: Session,
    flight_id: int,
    seat_numbers: List[str],
    booking_id: int = None,
    hold_duration_minutes: int = 10
) -> List[SeatHold]:
    """Hold seats for a specified duration"""
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    held_until = now + timedelta(minutes=hold_duration_minutes)
    
    # Check if seats are available
    available_seats_resp = get_available_seats(db, flight_id, include_held=False)
    available_seats = available_seats_resp["seat_map"]
    
    holds = []
    for seat in seat_numbers:
        if seat not in available_seats:
            raise ValueError(f"Seat {seat} does not exist")
        
        if not available_seats[seat]["available"]:
            raise ValueError(f"Seat {seat} is not available")
        
        # Create or update hold
        existing_hold = db.query(SeatHold).filter(
            SeatHold.flight_id == flight_id,
            SeatHold.seat_number == seat,
            SeatHold.held_until > now
        ).first()
        
        if existing_hold:
            existing_hold.held_until = held_until
            existing_hold.booking_id = booking_id
            holds.append(existing_hold)
        else:
            hold = SeatHold(
                flight_id=flight_id,
                seat_number=seat,
                held_until=held_until,
                booking_id=booking_id
            )
            db.add(hold)
            holds.append(hold)
    
    db.commit()
    return holds


def release_expired_holds(db: Session):
    """Release all expired seat holds"""
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    expired_holds = db.query(SeatHold).filter(SeatHold.held_until <= now).all()
    for hold in expired_holds:
        db.delete(hold)
    db.commit()


def release_holds_for_booking(db: Session, booking_id: int):
    """Release all holds for a specific booking"""
    holds = db.query(SeatHold).filter(SeatHold.booking_id == booking_id).all()
    for hold in holds:
        db.delete(hold)
    db.commit()

