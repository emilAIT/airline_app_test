from fastapi import APIRouter

from app.api.routes import login, private, users, utils, airports, airplanes, flights, bookings, tickets, payments, seat_holds, checkins, announcements
from app.core.config import settings

api_router = APIRouter()
api_router.include_router(login.router)
api_router.include_router(users.router)
api_router.include_router(utils.router)
api_router.include_router(airports.router)
api_router.include_router(airplanes.router)
api_router.include_router(flights.router)
api_router.include_router(bookings.router)
api_router.include_router(tickets.router)
api_router.include_router(payments.router)
api_router.include_router(seat_holds.router)
api_router.include_router(checkins.router)
api_router.include_router(announcements.router)


if settings.ENVIRONMENT == "local":
    api_router.include_router(private.router)
