from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.airplane import Airplane


def create_airplane(
    db: Session,
    model: str,
    registration_number: str,
    seat_template: dict,
    total_seats: int
) -> Airplane:
    """
    Create a new airplane with seat template (staff only).
    Per instructions.txt lines 214-219.
    """
    # Check if registration number already exists
    existing = db.query(Airplane).filter(
        Airplane.registration_number == registration_number
    ).first()
    if existing:
        raise HTTPException(
            status_code=status. HTTP_400_BAD_REQUEST,
            detail=f"Airplane with registration number {registration_number} already exists"
        )
    
    airplane = Airplane(
        model=model,
        registration_number=registration_number,
        seat_template=seat_template,
        total_seats=total_seats
    )
    db.add(airplane)
    db.commit()
    db.refresh(airplane)
    return airplane


def get_airplane(db: Session, airplane_id: int) -> Airplane:
    """Get a single airplane"""
    airplane = db.query(Airplane).filter(Airplane.id == airplane_id).first()
    if not airplane:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airplane not found"
        )
    return airplane


def list_airplanes(db: Session) -> list:
    """List all airplanes"""
    return db.query(Airplane).all()


def update_airplane(
    db: Session,
    airplane_id: int,
    model: str = None,
    seat_template: dict = None,
    total_seats: int = None
) -> Airplane:
    """Update airplane details (staff only)"""
    airplane = get_airplane(db, airplane_id)
    
    if model:
        airplane.model = model
    if seat_template:
        airplane.seat_template = seat_template
    if total_seats:
        airplane.total_seats = total_seats
    
    db.commit()
    db.refresh(airplane)
    return airplane


def delete_airplane(db: Session, airplane_id: int):
    """Delete an airplane (staff only)"""
    airplane = get_airplane(db, airplane_id)
    
    # Check if airplane has flights
    if airplane.flights:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete airplane with existing flights"
        )
    
    db.delete(airplane)
    db.commit()
    return {"message": "Airplane deleted successfully"}
