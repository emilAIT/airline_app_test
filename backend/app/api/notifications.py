"""Notifications API routes - passenger notifications."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.notification import Notification
from pydantic import BaseModel


router = APIRouter()


class NotificationResponse(BaseModel):
    """Notification response schema."""
    id: int
    flight_id: int
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: str
    
    class Config:
        from_attributes = True


@router.get("", response_model=List[NotificationResponse])
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all notifications for current user.
    
    Returns notifications in reverse chronological order (newest first).
    """
    notifications = db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).order_by(Notification.created_at.desc()).all()
    
    return [
        NotificationResponse(
            id=n.id,
            flight_id=n.flight_id,
            title=n.title,
            message=n.message,
            notification_type=n.notification_type,
            is_read=n.is_read,
            created_at=n.created_at.isoformat()
        )
        for n in notifications
    ]


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_as_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark notification as read."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        from app.core.exceptions import NotFound
        raise NotFound("Notification")
    
    notification.is_read = True
    notification.read_at = datetime.utcnow()
    db.commit()
    db.refresh(notification)
    
    return NotificationResponse(
        id=notification.id,
        flight_id=notification.flight_id,
        title=notification.title,
        message=notification.message,
        notification_type=notification.notification_type,
        is_read=notification.is_read,
        created_at=notification.created_at.isoformat()
    )


@router.get("/unread-count", response_model=dict)
def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get count of unread notifications."""
    unread_count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    
    return {"unread_count": unread_count}
