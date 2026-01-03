"""
Airport repository - database operations for airports.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.airport import Airport


class AirportRepository:
    """
    Data access layer for Airport model.
    Airports are reference data (read-only for most users).
    """
    
    def get_all(self, db: Session) -> List[Airport]:
        """Get all airports."""
        return db.query(Airport).order_by(Airport.city).all()
    
    def get_by_id(self, db: Session, airport_id: int) -> Optional[Airport]:
        """Get airport by ID."""
        return db.query(Airport).filter(Airport.id == airport_id).first()
    
    def get_by_code(self, db: Session, code: str) -> Optional[Airport]:
        """Get airport by IATA code (case-insensitive)."""
        return db.query(Airport).filter(Airport.code == code.upper()).first()
    
    def create(self, db: Session, **airport_data) -> Airport:
        """Create new airport (staff only)."""
        # Normalize code to uppercase
        if 'code' in airport_data:
            airport_data['code'] = airport_data['code'].upper()
        
        airport = Airport(**airport_data)
        db.add(airport)
        db.flush()
        db.refresh(airport)
        return airport


# Singleton
airport_repository = AirportRepository()
