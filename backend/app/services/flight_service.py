"""
Flight service - business logic for flight operations.
"""
from typing import List, Optional, Dict
from datetime import date, datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.flight import Flight
from app.models.airplane import Airplane
from app.models.seat_hold import SeatHold
from app.models.ticket import Ticket
from app.repositories.flight import flight_repository
from app.services.seat_generator import generate_seat_map, calculate_airplane_layout, SeatInfo
from app.core.exceptions import NotFound, ValidationError


class SeatStatus:
    """Seat availability status constants."""
    AVAILABLE = "available"
    HELD = "held"
    SOLD = "sold"


class SeatMapItem:
    """Seat map item with availability status."""
    def __init__(self, seat_info: SeatInfo, status: str, held_by: Optional[int] = None):
        self.seat_number = seat_info.seat_number
        self.seat_class = seat_info.seat_class
        self.row = seat_info.row
        self.letter = seat_info.letter
        self.status = status
        self.held_by = held_by  # user_id if held/sold


class FlightService:
    """Service layer for flight operations."""
    
    def search_flights(
        self,
        db: Session,
        origin_id: Optional[int] = None,
        destination_id: Optional[int] = None,
        departure_date: Optional[date] = None,
        status: str = "SCHEDULED"
    ):
        """
        Search for flights with filters and return availability.
        
        Optimized query:
        - Joins Flight → Airplane (for total_seats)
        - Outer Joins Flight → SeatHold (for taken seats)
        - Groups by Flight to count taken seats
        - Calculates available_seats = total_seats - taken_seats
        """
        from sqlalchemy import func, or_, case
        
        # Base query: Flight + Count(active_holds)
        # We need to count SeatHolds that are either:
        # 1. Not expired (held_until > now)
        # 2. Booked (booking_id is not null)
        now = datetime.utcnow()
        
        # Construct filters
        filters = [Flight.status == status]
        if origin_id:
            filters.append(Flight.origin_airport_id == origin_id)
        if destination_id:
            filters.append(Flight.destination_airport_id == destination_id)
        if departure_date:
            from datetime import timedelta
            next_day = departure_date + timedelta(days=1)
            filters.append(
                and_(
                    Flight.departure_time >= datetime.combine(departure_date, datetime.min.time()),
                    Flight.departure_time < datetime.combine(next_day, datetime.min.time())
                )
            )
            
        # Join logic
        # taken_seats_count = count(SeatHold) where conditions met
        query = (
            db.query(Flight, func.count(SeatHold.id).label("taken_seats"))
            .outerjoin(SeatHold, and_(
                SeatHold.flight_id == Flight.id,
                or_(
                    SeatHold.held_until > now,
                    SeatHold.booking_id.isnot(None)
                )
            ))
            .filter(and_(*filters))
            .group_by(Flight.id)
            .order_by(Flight.departure_time)
        )
        
        print(f"DEBUG SEARCH: origin={origin_id}, dest={destination_id}, date={departure_date}, status={status}")
        results = query.all()
        print(f"DEBUG SEARCH: Found {len(results)} flights")
        return results
    
    
    def get_seat_map(self, db: Session, flight_id: int) -> List[Dict]:
        """
        Generate dynamic seat map for a flight with availability status.
        
        This is the CORE METHOD that combines:
            1. Generated seat grid (from airplane capacity)
            2. Seat holds (temporary reservations)
            3. Sold tickets (confirmed bookings)
        
        Algorithm:
            1. Get flight and airplane
            2. Generate complete seat grid from airplane.total_seats
            3. Query seat_holds and tickets for this flight
            4. Mark each seat as: available, held, or sold
        
        Args:
            flight_id: ID of the flight
        
        Returns:
            List of seat map items with status
            
        Raises:
            NotFound: If flight doesn't exist
        """
        print(f"DEBUG: Calculating seat map for flight {flight_id}")
        try:
            # Get flight with airplane
            flight = db.query(Flight).filter(Flight.id == flight_id).first()
            if not flight:
                raise NotFound("Flight")
            
            airplane = db.query(Airplane).filter(Airplane.id == flight.airplane_id).first()
            if not airplane:
                raise NotFound("Airplane")
            
            # Generate seat grid dynamically
            layout = calculate_airplane_layout(airplane.total_seats)
            print(f"DEBUG: Layout calculated: {layout}")
            all_seats = generate_seat_map(
                total_seats=airplane.total_seats,
                extra_legroom_rows=layout["extra_legroom_rows"]
            )
        except Exception as e:
            print(f"ERROR in get_seat_map: {e}")
            import traceback
            traceback.print_exc()
            raise e
        
        
        # Get all seat holds for this flight
        try:
            seat_holds = db.query(SeatHold).filter(SeatHold.flight_id == flight_id).all()
            
            # Filter holds: either not expired OR confirmed (has booking_id)
            active_holds = {}
            now = datetime.utcnow()
            
            for hold in seat_holds:
                is_active_hold = (hold.booking_id is None) and (hold.held_until > now)
                is_confirmed = (hold.booking_id is not None)
                
                if is_active_hold or is_confirmed:
                    active_holds[hold.seat_number] = hold.user_id
        except Exception as e:
            print(f"ERROR querying seat holds: {e}")
            raise e
        
        # Get sold tickets
        sold_tickets = db.query(Ticket).filter(
            Ticket.flight_id == flight_id
        ).all()
        
        sold_seats = {
            ticket.seat_number: ticket.booking_id 
            for ticket in sold_tickets
        }
        
        # Build seat map with status
        seat_map = []
        for seat_info in all_seats:
            if seat_info.seat_number in sold_seats:
                status = SeatStatus.SOLD
                held_by = sold_seats[seat_info.seat_number]
            elif seat_info.seat_number in active_holds:
                status = SeatStatus.HELD
                held_by = active_holds[seat_info.seat_number]
            else:
                status = SeatStatus.AVAILABLE
                held_by = None
            
            seat_map.append({
                "seat_number": seat_info.seat_number,
                "seat_class": seat_info.seat_class,
                "row": seat_info.row,
                "letter": seat_info.letter,
                "status": status,
                "held_by": held_by
            })
        
        return seat_map
    
    
    def get_available_seats(self, db: Session, flight_id: int) -> List[str]:
        """
        Get list of available seat numbers for a flight.
        
        Useful for booking validation.
        """
        seat_map = self.get_seat_map(db, flight_id)
        return [
            seat["seat_number"] 
            for seat in seat_map 
            if seat["status"] == SeatStatus.AVAILABLE
        ]


# Singleton instance
flight_service = FlightService()
