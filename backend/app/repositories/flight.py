"""Flight repository."""
from typing import List, Optional
from datetime import date, datetime
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_
from app.models import Flight


class FlightRepository:
    """Data access layer for flights."""
    
    def get_by_id(self, db: Session, flight_id: int) -> Optional[Flight]:
        """Get flight with relationships."""
        return (db.query(Flight)
                .options(
                    joinedload(Flight.airplane),
                    joinedload(Flight.origin),
                    joinedload(Flight.destination)
                )
                .filter(Flight.id == flight_id)
                .first())
    
    def search(
        self,
        db: Session,
        origin_code: str,
        destination_code: str,
        departure_date: date
    ) -> List[Flight]:
        """Search flights by route and date."""
        # Convert date to datetime range (start/end of day)
        start_of_day = datetime.combine(departure_date, datetime.min.time())
        end_of_day = datetime.combine(departure_date, datetime.max.time())
        
        return (db.query(Flight)
                .join(Flight.origin)
                .join(Flight.destination)
                .options(
                    joinedload(Flight.airplane),
                    joinedload(Flight.origin),
                    joinedload(Flight.destination)
                )
                .filter(
                    and_(
                        Flight.departure_time >= start_of_day,
                        Flight.departure_time <= end_of_day
                    )
                )
                # Filter by airport codes via joins
                .filter(Flight.origin.has(code=origin_code.upper()))
                .filter(Flight.destination.has(code=destination_code.upper()))
                .order_by(Flight.departure_time)
                .all())
    
    def create(self, db: Session, **flight_data) -> Flight:
        """Create flight (staff only)."""
        flight = Flight(**flight_data)
        db.add(flight)
        db.flush()
        db.refresh(flight)
        return flight
    
    def update_status(self, db: Session, flight: Flight, new_status: str) -> Flight:
        """Update flight status."""
        flight.status = new_status
        db.flush()
        db.refresh(flight)
        return flight


flight_repository = FlightRepository()
