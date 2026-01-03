from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.routers import deps
from app.schemas import user as user_schema
from app.models import user as user_model
from app.models import flight as flight_model

router = APIRouter()

@router.get("/me", response_model=user_schema.User)
def read_user_me(
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    return current_user

@router.put("/me/profile", response_model=user_schema.User)
def update_user_profile(
    *,
    db: Session = Depends(deps.get_db),
    profile_in: user_schema.PassengerProfileCreate,
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    if current_user.role != user_model.UserRole.PASSENGER:
         # Depending on requirements, staff might also have profiles, but requirement says "Passenger Profile"
         pass

    if not current_user.profile:
        # Create new profile
        profile = user_model.PassengerProfile(
            **profile_in.model_dump(), user_id=current_user.id
        )
        db.add(profile)
    else:
        # Update existing
        for field, value in profile_in.model_dump(exclude_unset=True).items():
            setattr(current_user.profile, field, value)
        
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/me/notifications", response_model=List[user_schema.UserNotification])
def get_user_notifications(
    *,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """Get all notifications for the current user"""
    notifications = db.query(flight_model.UserNotification).filter(
        flight_model.UserNotification.user_id == current_user.id
    ).order_by(flight_model.UserNotification.created_at.desc()).offset(skip).limit(limit).all()
    return notifications

@router.get("/me/notifications/unread-count", response_model=dict)
def get_unread_notifications_count(
    *,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    """Get count of unread notifications for the current user"""
    count = db.query(flight_model.UserNotification).filter(
        flight_model.UserNotification.user_id == current_user.id,
        flight_model.UserNotification.is_read == False
    ).count()
    return {"unread_count": count}

@router.put("/me/notifications/{notification_id}/read", response_model=user_schema.UserNotification)
def mark_notification_as_read(
    *,
    db: Session = Depends(deps.get_db),
    notification_id: int,
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    """Mark a notification as read"""
    notification = db.query(flight_model.UserNotification).filter(
        flight_model.UserNotification.id == notification_id,
        flight_model.UserNotification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification

@router.put("/me/notifications/read-all", response_model=dict)
def mark_all_notifications_as_read(
    *,
    db: Session = Depends(deps.get_db),
    current_user: user_model.User = Depends(deps.get_current_active_user),
) -> Any:
    """Mark all notifications as read for the current user"""
    updated = db.query(flight_model.UserNotification).filter(
        flight_model.UserNotification.user_id == current_user.id,
        flight_model.UserNotification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"updated_count": updated}
