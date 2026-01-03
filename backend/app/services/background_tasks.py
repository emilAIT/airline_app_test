"""
Background tasks - scheduled cleanup and maintenance.
"""
from datetime import datetime
import logging
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.repositories.seat_hold import seat_hold_repository

logger = logging.getLogger(__name__)


def cleanup_expired_seat_holds():
    """
    Background task: delete expired seat holds.
    
    Runs every minute (configured in main.py).
    - Deletes orphan holds (booking_id IS NULL)
    - Cancels CREATED bookings whose holds expired and deletes their holds
    """
    db: Session = SessionLocal()
    try:
        now = datetime.utcnow()

        deleted_count = seat_hold_repository.delete_expired_holds(db, now)
        cancelled = seat_hold_repository.cancel_expired_created_bookings(db, now)

        if deleted_count > 0 or cancelled > 0:
            logger.info(f"🧹 Cleaned up holds={deleted_count}, cancelled_bookings={cancelled}")
        
        db.commit()
        
    except Exception as e:
        logger.error(f"Error in cleanup task: {e}")
        db.rollback()
    finally:
        db.close()
