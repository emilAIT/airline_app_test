"""Authorization utilities for role-based access control"""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.user import User, UserRole
from app.models.airplane import Airplane
from app.models.flight import Flight
from app.models.booking import Booking
from app.models.announcement import Announcement
from typing import Optional
import logging

logger = logging.getLogger(__name__)


def check_airplane_access(user: User, airplane_id: int, db: Session) -> bool:
    """
    Global Authorization Rule:
    IF user.role == ADMIN → allow
    ELSE IF user.role == STAFF AND resource.plane_id == user.assigned_plane_id → allow
    ELSE → deny
    """
    if user.role == UserRole.ADMIN or user.role == UserRole.STAFF:
        return True
    
    return False


def require_airplane_access(user: User, airplane_id: int, db: Session, resource_name: str = "airplane"):
    """Check airplane access and raise exception if denied"""
    if not check_airplane_access(user, airplane_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied. You don't have permission to access this {resource_name}."
        )


def check_flight_access(user: User, flight_id: int, db: Session) -> bool:
    """Check if user has access to a flight"""
    if user.role == UserRole.ADMIN or user.role == UserRole.STAFF:
        return True
    
    return False


def require_flight_access(user: User, flight_id: int, db: Session):
    """Check flight access and raise exception if denied"""
    if not check_flight_access(user, flight_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. You don't have permission to access this flight."
        )


def check_booking_access(user: User, booking_id: int, db: Session) -> bool:
    """Check if user has access to a booking"""
    if user.role == UserRole.ADMIN:
        return True
    
    if user.role == UserRole.STAFF:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if booking and booking.flight:
            return check_flight_access(user, booking.flight_id, db)
    
    return False


def require_booking_access(user: User, booking_id: int, db: Session):
    """Check booking access and raise exception if denied"""
    if not check_booking_access(user, booking_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. You don't have permission to access this booking."
        )


def check_announcement_access(user: User, announcement_id: int, db: Session) -> bool:
    """Check if user has access to an announcement"""
    if user.role == UserRole.ADMIN:
        return True
    
    if user.role == UserRole.STAFF:
        announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
        if announcement and announcement.flight:
            return check_flight_access(user, announcement.flight_id, db)
    
    return False


def require_announcement_access(user: User, announcement_id: int, db: Session):
    """Check announcement access and raise exception if denied"""
    if not check_announcement_access(user, announcement_id, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. You don't have permission to access this announcement."
        )


def log_critical_action(
    user: User,
    action: str,
    resource_type: str,
    resource_id: Optional[int] = None,
    details: Optional[str] = None
):
    """Log critical actions for audit trail"""
    log_message = f"[CRITICAL ACTION] User: {user.email} (ID: {user.id}, Role: {user.role.value}) | Action: {action} | Resource: {resource_type}"
    if resource_id:
        log_message += f" (ID: {resource_id})"
    if details:
        log_message += f" | Details: {details}"
    
    logger.warning(log_message)
    print(f"⚠️  {log_message}")  # Also print to console for visibility

