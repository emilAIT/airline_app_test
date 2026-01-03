"""
Helper functions to automatically create announcements based on flight times
"""
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models import flight as flight_model
from app.models import booking as booking_model


def create_time_based_announcements(db: Session) -> None:
    """
    Check all upcoming flights and create announcements when:
    - Check-in window opens (24 hours before departure)
    - Boarding starts (40 minutes before departure)
    - Flight approaching (3 hours before departure)
    Also automatically update flight status to DEPARTED when departure time passes
    """
    now = datetime.utcnow()
    
    # Auto-update flight status to DEPARTED for flights that have departed
    departed_flights = db.query(flight_model.Flight).filter(
        flight_model.Flight.status == flight_model.FlightStatus.SCHEDULED,
        flight_model.Flight.departure_time <= now
    ).all()
    
    for flight in departed_flights:
        flight.status = flight_model.FlightStatus.DEPARTED
    db.commit()
    
    # Get all upcoming confirmed flights (excluding cancelled and departed)
    flights = db.query(flight_model.Flight).filter(
        flight_model.Flight.status != flight_model.FlightStatus.CANCELLED,
        flight_model.Flight.status != flight_model.FlightStatus.DEPARTED,
        flight_model.Flight.departure_time > now
    ).all()
    
    for flight in flights:
        departure = flight.departure_time
        time_until_departure = departure - now
        
        # Check if check-in window just opened (24 hours before, within last hour)
        check_in_start = departure - timedelta(hours=24)
        if timedelta(hours=0) <= (now - check_in_start) <= timedelta(hours=1):
            # Check if announcement already exists
            existing = db.query(flight_model.Announcement).filter(
                flight_model.Announcement.flight_id == flight.id,
                flight_model.Announcement.title == "Check-in Now Available",
                flight_model.Announcement.created_at >= check_in_start - timedelta(hours=1)
            ).first()
            
            if not existing:
                # Check if flight has confirmed bookings
                has_bookings = db.query(booking_model.Booking).filter(
                    booking_model.Booking.flight_id == flight.id,
                    booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
                ).first()
                
                if has_bookings:
                    announcement = flight_model.Announcement(
                        flight_id=flight.id,
                        title="Check-in Now Available",
                        message=f"Online check-in is now available for flight {flight.flight_number}. Check-in window: 24 hours to 1 hour before departure.",
                        type=flight_model.AnnouncementType.GENERAL_INFO,
                        created_at=now
                    )
                    db.add(announcement)
        
        # Check if boarding should start (1 hour before departure, within last 10 minutes)
        boarding_one_hour = departure - timedelta(hours=1)
        if timedelta(minutes=0) <= (now - boarding_one_hour) <= timedelta(minutes=10):
            # Only process if flight status is still SCHEDULED (not already BOARDING)
            if flight.status == flight_model.FlightStatus.SCHEDULED:
                # Check if we already created notifications for this flight in this time window
                # by checking if any user with a booking on this flight has a notification about boarding
                bookings = db.query(booking_model.Booking).filter(
                    booking_model.Booking.flight_id == flight.id,
                    booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
                ).all()
                
                if bookings:
                    # Check if any notification already exists for this flight about boarding
                    user_ids = [b.user_id for b in bookings]
                    existing_notification = db.query(flight_model.UserNotification).filter(
                        flight_model.UserNotification.user_id.in_(user_ids),
                        flight_model.UserNotification.message.like(f"%Boarding has started for flight {flight.flight_number}%"),
                        flight_model.UserNotification.created_at >= boarding_one_hour - timedelta(minutes=10)
                    ).first()
                    
                    if not existing_notification:
                        # Update flight status to BOARDING
                        flight.status = flight_model.FlightStatus.BOARDING
                        
                        # Create notifications for each user
                        gate_info = f" at gate {flight.gate}" if flight.gate else ""
                        for booking in bookings:
                            notification = flight_model.UserNotification(
                                user_id=booking.user_id,
                                type=flight_model.UserNotificationType.FLIGHT_UPDATE,
                                message=f"Boarding has started for flight {flight.flight_number}{gate_info}. Please proceed to the gate with your boarding pass.",
                                created_at=now,
                                is_read=False
                            )
                            db.add(notification)
        
        # Check if boarding is starting (40 minutes before, within last 10 minutes)
        boarding_start = departure - timedelta(minutes=40)
        if timedelta(minutes=0) <= (now - boarding_start) <= timedelta(minutes=10):
            existing = db.query(flight_model.Announcement).filter(
                flight_model.Announcement.flight_id == flight.id,
                flight_model.Announcement.title == "Boarding Started",
                flight_model.Announcement.created_at >= boarding_start - timedelta(minutes=10)
            ).first()
            
            if not existing:
                has_bookings = db.query(booking_model.Booking).filter(
                    booking_model.Booking.flight_id == flight.id,
                    booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
                ).first()
                
                if has_bookings:
                    gate_info = f" at gate {flight.gate}" if flight.gate else ""
                    announcement = flight_model.Announcement(
                        flight_id=flight.id,
                        title="Boarding Started",
                        message=f"Boarding has started for flight {flight.flight_number}{gate_info}. Please proceed to the gate with your boarding pass.",
                        type=flight_model.AnnouncementType.BOARDING_STARTED,
                        created_at=now
                    )
                    db.add(announcement)
        
        # Check if flight is approaching (3 hours before, within last 30 minutes)
        approaching_time = departure - timedelta(hours=3)
        if timedelta(minutes=0) <= (now - approaching_time) <= timedelta(minutes=30):
            existing = db.query(flight_model.Announcement).filter(
                flight_model.Announcement.flight_id == flight.id,
                flight_model.Announcement.title.like("Flight Approaching%"),
                flight_model.Announcement.created_at >= approaching_time - timedelta(minutes=30)
            ).first()
            
            if not existing:
                has_bookings = db.query(booking_model.Booking).filter(
                    booking_model.Booking.flight_id == flight.id,
                    booking_model.Booking.status == booking_model.BookingStatus.CONFIRMED
                ).first()
                
                if has_bookings:
                    announcement = flight_model.Announcement(
                        flight_id=flight.id,
                        title="Flight Approaching",
                        message=f"Flight {flight.flight_number} departs in 3 hours. Please prepare for check-in which opens 24 hours before departure.",
                        type=flight_model.AnnouncementType.GENERAL_INFO,
                        created_at=now
                    )
                    db.add(announcement)
    
    db.commit()

