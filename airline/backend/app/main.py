import os
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from app.database import engine, Base, SessionLocal
from app.routers import auth, flights, bookings, passenger, payments, checkin, announcements, staff, photos, admin_rules, notifications
from app.models import all_models
from app.services.seat_service import cleanup_expired_holds
from app.services.booking_service import expire_bookings
import time
from threading import Thread
import traceback

# Create tables on startup
all_models.Base.metadata.create_all(bind=engine)


def run_cleanup_task():
    """Background task to cleanup expired seat holds and bookings every minute"""
    while True:
        try:
            db = SessionLocal()
            try:
                cleanup_expired_holds(db)
                expired_count = expire_bookings(db)
                if expired_count > 0:
                    print(f"Expired {expired_count} booking(s) due to timeout")
            finally:
                db.close()
        except Exception as e:
            print(f"Error in cleanup task: {e}")
            import traceback
            traceback.print_exc()
        time.sleep(60)  # Run every minute


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Start background task
    cleanup_thread = Thread(target=run_cleanup_task, daemon=True)
    cleanup_thread.start()
    yield
    # Shutdown: cleanup if needed
    pass


app = FastAPI(
    title="ELDIK AirLines - Booking & Operations API",
    version="1.0.0",
    description="Premium airline booking and operations management system for ELDIK AirLines",
    lifespan=lifespan
)

# Add CORS middleware - MUST be before other middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Global exception handler to ensure CORS headers are always sent


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all exceptions and ensure CORS headers are sent"""
    import traceback
    error_detail = str(exc)
    print(f"Unhandled exception: {error_detail}")
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": f"Internal server error: {error_detail}"},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
            "Access-Control-Allow-Headers": "*",
        }
    )

# Include all routers
app.include_router(auth.router)
app.include_router(flights.router)
app.include_router(bookings.router)
app.include_router(passenger.router)
app.include_router(payments.router)
app.include_router(checkin.router)
app.include_router(announcements.router)
app.include_router(staff.router)
app.include_router(photos.router)  # Added photos router
app.include_router(admin_rules.router)
app.include_router(notifications.router)


# Mount static files
os.makedirs("media/photos", exist_ok=True)
app.mount("/media", StaticFiles(directory="media"), name="media")


@app.get("/")
def home():
    return {
        "message": "ELDIK AirLines - Booking & Operations API",
        "docs": "/docs",
        "version": "1.0.0"
    }
