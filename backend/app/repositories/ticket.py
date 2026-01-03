"""Ticket repository."""
from sqlalchemy.orm import Session
from app.models.ticket import Ticket


class TicketRepository:
    """Data access layer for tickets."""
    
    def create(
        self,
        db: Session,
        booking_id: int,
        flight_id: int,
        ticket_number: str,
        passenger_id: int,
        seat_id: int,
        passenger_first_name: str,
        passenger_last_name: str,
        seat_number: str,
        price: float
    ) -> Ticket:
        """Create ticket."""
        ticket = Ticket(
            booking_id=booking_id,
            flight_id=flight_id,
            ticket_number=ticket_number,
            passenger_id=passenger_id,
            seat_id=seat_id,
            passenger_first_name=passenger_first_name,
            passenger_last_name=passenger_last_name,
            seat_number=seat_number,
            price=price
        )
        db.add(ticket)
        db.flush()
        db.refresh(ticket)
        return ticket
    
    def get_by_ticket_number(self, db: Session, ticket_number: str):
        """Get ticket by number."""
        return db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first()


ticket_repository = TicketRepository()
