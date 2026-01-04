"""
Notification Service - Handles all notification logic
Clean, readable code for notification management
"""
from sqlmodel import Session, select
from datetime import datetime
from typing import List, Optional
from app.models import (
    Notification, NotificationType, User, Booking, Flight, 
    BookingStatus, UserRole
)


class NotificationService:
    """Service for managing user notifications"""
    
    def __init__(self, session: Session):
        self.session = session
    
    # ==================== CREATE NOTIFICATIONS ====================
    
    def create_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        title: str,
        message: str,
        booking_id: Optional[int] = None,
        flight_id: Optional[int] = None
    ) -> Notification:
        # DEBUG LOGGING
        print(f"DEBUG: Creating notification | User: {user_id} | Type: {notification_type} | Title: {title}")
        
        """Create a single notification for a user"""
        notification = Notification(
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            message=message,
            booking_id=booking_id,
            flight_id=flight_id,
            is_read=False,
            created_at=datetime.now()
        )
        self.session.add(notification)
        self.session.commit()
        self.session.refresh(notification)
        return notification
    
    def notify_booking_created(self, booking: Booking) -> Notification:
        """Send notification when booking is created"""
        flight = self.session.get(Flight, booking.flight_id)
        flight_info = f"{flight.flight_number}" if flight else "Unknown"
        
        return self.create_notification(
            user_id=booking.user_id,
            notification_type=NotificationType.BOOKING_CREATED,
            title="Бронь создана",
            message=f"Бронь {booking.booking_reference} на рейс {flight_info} создана. Оплатите в течение 10 минут.",
            booking_id=booking.id,
            flight_id=booking.flight_id
        )
    
    def notify_booking_paid(self, booking: Booking) -> Notification:
        """Send notification when booking is paid"""
        flight = self.session.get(Flight, booking.flight_id)
        flight_info = f"{flight.flight_number}" if flight else "Unknown"
        
        return self.create_notification(
            user_id=booking.user_id,
            notification_type=NotificationType.BOOKING_PAID,
            title="Оплата успешна!",
            message=f"Билет на рейс {flight_info} успешно оплачен. Номер брони: {booking.booking_reference}",
            booking_id=booking.id,
            flight_id=booking.flight_id
        )
    
    def notify_booking_expired(self, booking: Booking) -> Notification:
        """Send notification when booking expires"""
        return self.create_notification(
            user_id=booking.user_id,
            notification_type=NotificationType.BOOKING_EXPIRED,
            title="Бронь истекла",
            message=f"Бронь {booking.booking_reference} отменена из-за истечения времени оплаты.",
            booking_id=booking.id,
            flight_id=booking.flight_id
        )
    
    def notify_flight_update(
        self, 
        flight: Flight, 
        update_title: str, 
        update_message: str
    ) -> List[Notification]:
        """Notify all passengers of a flight about an update"""
        # Get all users with bookings on this flight
        bookings = self.session.exec(
            select(Booking).where(
                Booking.flight_id == flight.id,
                Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
            )
        ).all()
        
        notifications = []
        notified_users = set()  # Avoid duplicate notifications
        
        for booking in bookings:
            if booking.user_id not in notified_users:
                notification = self.create_notification(
                    user_id=booking.user_id,
                    notification_type=NotificationType.FLIGHT_UPDATE,
                    title=update_title,
                    message=update_message,
                    flight_id=flight.id
                )
                notifications.append(notification)
                notified_users.add(booking.user_id)
        
        return notifications
    
    def create_staff_announcement(
        self,
        flight_id: int,
        staff_user: User,
        title: str,
        message: str
    ) -> List[Notification]:
        """Staff sends announcement to all passengers on a flight"""
        if staff_user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise ValueError("Only staff can send announcements")
        
        flight = self.session.get(Flight, flight_id)
        if not flight:
            raise ValueError("Flight not found")
        
        # Get all passengers with paid bookings
        bookings = self.session.exec(
            select(Booking).where(
                Booking.flight_id == flight_id,
                Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
            )
        ).all()
        
        notifications = []
        notified_users = set()
        
        for booking in bookings:
            if booking.user_id not in notified_users:
                notification = self.create_notification(
                    user_id=booking.user_id,
                    notification_type=NotificationType.STAFF_ANNOUNCEMENT,
                    title=title,
                    message=message,
                    flight_id=flight_id
                )
                notifications.append(notification)
                notified_users.add(booking.user_id)
        
        return notifications

    def create_announcement_for_all_flights(
        self,
        staff_user: User,
        title: str,
        message: str,
        announcement_type: str = "general"
    ) -> List[Notification]:
        """Staff sends announcement to all passengers on all flights"""
        if staff_user.role not in [UserRole.STAFF, UserRole.ADMIN]:
            raise ValueError("Only staff can send announcements")
        
        # Get all flights
        if staff_user.role == UserRole.ADMIN:
            flights = self.session.exec(select(Flight)).all()
        else:
            flights = self.session.exec(
                select(Flight).where(Flight.owner_id == staff_user.id)
            ).all()
        
        notifications = []
        notified_users = set()
        
        for flight in flights:
            bookings = self.session.exec(
                select(Booking).where(
                    Booking.flight_id == flight.id,
                    Booking.status.in_([BookingStatus.PAID, BookingStatus.CHECKED_IN])
                )
            ).all()
            
            for booking in bookings:
                if booking.user_id not in notified_users:
                    notification = self.create_notification(
                        user_id=booking.user_id,
                        notification_type=NotificationType.STAFF_ANNOUNCEMENT,
                        title=title,
                        message=message,
                        flight_id=flight.id
                    )
                    notifications.append(notification)
                    notified_users.add(booking.user_id)
        
        return notifications

    # Назначение: Уведомление всех пассажиров о смене gate
    # Принимает: flight объект
    # Возвращает: список отправленных уведомлений
    def notify_gate_change(self, flight: Flight) -> List[Notification]:
        bookings = self.session.exec(
            select(Booking).where(
                Booking.flight_id == flight.id,
                Booking.status.notin_([BookingStatus.CANCELLED, BookingStatus.REFUNDED])
            )
        ).all()

        notifications = []
        for booking in bookings:
            notifications.append(
                self.create_notification(
                    user_id=booking.user_id,
                    notification_type=NotificationType.FLIGHT_UPDATE,
                    title="Gate updated",
                    message=f"Рейс {flight.flight_number}: новый gate вылета {flight.gate_departure}, gate прилета {flight.gate_arrival}.",
                    flight_id=flight.id,
                    booking_id=booking.id
                )
            )
        return notifications
    
    # ==================== READ NOTIFICATIONS ====================
    
    def get_user_notifications(
        self, 
        user_id: int, 
        unread_only: bool = False,
        limit: int = 50
    ) -> List[Notification]:
        """Get notifications for a user"""
        query = select(Notification).where(
            Notification.user_id == user_id
        ).order_by(Notification.created_at.desc()).limit(limit)
        
        if unread_only:
            query = query.where(Notification.is_read == False)
        
        return list(self.session.exec(query).all())
    
    def get_unread_count(self, user_id: int) -> int:
        """Get count of unread notifications"""
        notifications = self.session.exec(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        ).all()
        return len(notifications)
    
    # ==================== UPDATE NOTIFICATIONS ====================
    
    def mark_as_read(self, notification_id: int, user_id: int) -> bool:
        """Mark a single notification as read"""
        notification = self.session.get(Notification, notification_id)
        if notification and notification.user_id == user_id:
            notification.is_read = True
            self.session.add(notification)
            self.session.commit()
            return True
        return False
    
    def mark_all_as_read(self, user_id: int) -> int:
        """Mark all notifications as read for a user"""
        notifications = self.session.exec(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        ).all()
        
        count = 0
        for notification in notifications:
            notification.is_read = True
            self.session.add(notification)
            count += 1
        
        self.session.commit()
        return count
