from fastapi import APIRouter
from app.api.routes import (
    auth, passengers, flights, bookings, payments, checkin, announcements, staff, admin, notifications
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(passengers.router)
api_router.include_router(flights.router)
api_router.include_router(bookings.router)
api_router.include_router(payments.router)
api_router.include_router(checkin.router)
api_router.include_router(announcements.router)
api_router.include_router(staff.router)
api_router.include_router(admin.router)
api_router.include_router(notifications.router)


