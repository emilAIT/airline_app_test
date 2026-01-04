"""
Notifications API - Clean, readable endpoints for notification management
"""
from fastapi import APIRouter, Depends, Body, HTTPException
from sqlmodel import Session
from typing import List, Optional
from app.database import get_session
from app.models import User, UserRole, Notification
from app.core.deps import get_current_user
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


# ==================== GET NOTIFICATIONS ====================

@router.get("/")
def get_my_notifications(
    unread_only: bool = False,
    limit: int = 50,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Get current user's notifications"""
    service = NotificationService(session)
    notifications = service.get_user_notifications(
        user_id=current_user.id,
        unread_only=unread_only,
        limit=limit
    )
    
    # Convert to dict for JSON response
    return [
        {
            "id": n.id,
            "type": n.notification_type.value,
            "title": n.title,
            "message": n.message,
            "is_read": n.is_read,
            "created_at": n.created_at.isoformat(),
            "booking_id": n.booking_id,
            "flight_id": n.flight_id
        }
        for n in notifications
    ]


@router.get("/unread-count")
def get_unread_count(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Get count of unread notifications"""
    service = NotificationService(session)
    count = service.get_unread_count(current_user.id)
    return {"unread_count": count}


# ==================== MARK AS READ ====================

@router.post("/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Mark a single notification as read"""
    service = NotificationService(session)
    success = service.mark_as_read(notification_id, current_user.id)
    
    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    return {"success": True}


@router.post("/mark-all-read")
def mark_all_read(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Mark all notifications as read"""
    service = NotificationService(session)
    count = service.mark_all_as_read(current_user.id)
    return {"marked_count": count}


# ==================== STAFF ANNOUNCEMENTS ====================

@router.post("/announce")
def send_staff_announcement(
    data: dict = Body(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """
    Staff sends announcement to all passengers on a flight.
    Only Staff and Admin can use this endpoint.
    Cannot send to individual users - only to all flight passengers.
    """
    # Check permissions
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN]:
        raise HTTPException(
            status_code=403, 
            detail="Only staff can send announcements"
        )
    
    flight_id = data.get("flight_id")
    title = data.get("title")
    message = data.get("message")
    
    if not all([flight_id, title, message]):
        raise HTTPException(
            status_code=400, 
            detail="flight_id, title, and message are required"
        )
    
    service = NotificationService(session)
    
    try:
        notifications = service.create_staff_announcement(
            flight_id=flight_id,
            staff_user=current_user,
            title=title,
            message=message
        )
        
        return {
            "success": True,
            "notifications_sent": len(notifications),
            "message": f"Announcement sent to {len(notifications)} passengers"
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/announce/all")
def send_announcement_to_all_flights(
    data: dict = Body(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """
    Staff sends announcement to all passengers on all their flights.
    Only Staff and Admin can use this endpoint.
    """
    # Check permissions
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN]:
        raise HTTPException(
            status_code=403, 
            detail="Only staff can send announcements"
        )
    
    title = data.get("title")
    message = data.get("message")
    announcement_type = data.get("announcement_type", "general")
    
    if not all([title, message]):
        raise HTTPException(
            status_code=400, 
            detail="title and message are required"
        )
    
    service = NotificationService(session)
    
    try:
        notifications = service.create_announcement_for_all_flights(
            staff_user=current_user,
            title=title,
            message=message,
            announcement_type=announcement_type
        )
        
        return {
            "success": True,
            "notifications_sent": len(notifications),
            "message": f"Announcement sent to {len(notifications)} passengers across all flights"
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))