"""FastAPI application entry point (exam-aligned minimal API)."""

import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.services.background_tasks import cleanup_expired_seat_holds


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting ZaKu backend...")
    init_db()
    print("Database initialized")
    
    # Initialize default seats if database is empty
    await asyncio.to_thread(_initialize_default_seats)

    stop_event = asyncio.Event()

    async def _cleanup_loop():
        while not stop_event.is_set():
            # Run in a thread to avoid blocking the event loop.
            await asyncio.to_thread(cleanup_expired_seat_holds)
            try:
                await asyncio.wait_for(stop_event.wait(), timeout=60)
            except asyncio.TimeoutError:
                continue

    task = asyncio.create_task(_cleanup_loop())
    yield
    stop_event.set()
    task.cancel()
    print("Shutting down ZaKu backend...")


def _initialize_default_seats():
    """Initialize default seats if database is empty."""
    from app.database import SessionLocal
    from app.models.seat import Seat
    from app.models.airplane import Airplane
    from app.models.user import User
    from app.models.airport import Airport
    from app.core.security import hash_password
    
    db = SessionLocal()
    try:
        # Check if users already exist
        user_count = db.query(User).count()
        if user_count == 0:
            print("Creating default users...")
            
            # Create staff user
            staff = User(
                email="staff@zaku.kz",
                hashed_password=hash_password("staff123"),
                role="STAFF"
            )
            
            # Create passenger user
            passenger = User(
                email="passenger@zaku.kz",
                hashed_password=hash_password("passenger123"),
                role="PASSENGER"
            )
            
            db.add(staff)
            db.add(passenger)
            db.flush()
            print(f"✅ Created staff user: staff@zaku.kz / staff123")
            print(f"✅ Created passenger user: passenger@zaku.kz / passenger123")
        
        # Check if airports already exist
        airport_count = db.query(Airport).count()
        if airport_count == 0:
            print("Creating default airports...")
            
            airports = [
                Airport(code="FRU", name="Manas International Airport", city="Bishkek"),
                Airport(code="OSS", name="Osh International Airport", city="Osh"),
                Airport(code="SVO", name="Sheremetyevo International Airport", city="Moscow"),
                Airport(code="LED", name="Pulkovo Airport", city="Saint Petersburg"),
                Airport(code="SVX", name="Koltsovo Airport", city="Yekaterinburg"),
            ]
            
            db.add_all(airports)
            db.flush()
            print(f"✅ Created {len(airports)} test airports")
        
        # Check if seats already exist
        seat_count = db.query(Seat).count()
        if seat_count > 0:
            print("Seats already exist, skipping initialization")
            db.commit()
            return
        
        print("Initializing default airplane and seats...")
        
        # Check if airplane exists, if not create one
        airplane = db.query(Airplane).filter(Airplane.id == 1).first()
        if not airplane:
            airplane = Airplane(
                id=1,
                registration_number="UP-B7701",
                model="Boeing 737-800",
                manufacturer="Boeing",
                total_seats=60
            )
            db.add(airplane)
            db.flush()
        
        # Create 60 seats (10 rows × 6 seats: A-F)
        seats = []
        seat_letters = ['A', 'B', 'C', 'D', 'E', 'F']
        
        for row in range(1, 11):
            for letter in seat_letters:
                seat = Seat(
                    airplane_id=airplane.id,
                    row_number=row,
                    seat_letter=letter,
                    category='extra_legroom' if row <= 3 else 'standard'
                )
                seats.append(seat)
        
        db.add_all(seats)
        db.commit()
        print(f"✅ Created {len(seats)} seats for airplane ID {airplane.id}")
        
    except Exception as e:
        print(f"❌ Error initializing: {e}")
        db.rollback()
    finally:
        db.close()


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="ZaKu Airline Booking System API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware for Flutter app - FIRST MIDDLEWARE
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint - health check."""
    return {
        "app": settings.app_name,
        "status": "running",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


# Register API routers
from app.api import airports, announcements, auth, bookings, checkin, flights, notifications, payments, profile, staff

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["Profile"])
app.include_router(airports.router, prefix="/api/v1/airports", tags=["Airports"])
app.include_router(flights.router, prefix="/api/v1/flights", tags=["Flights"])
app.include_router(bookings.router, prefix="/api/v1/bookings", tags=["Bookings"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["Notifications"])
app.include_router(payments.router, prefix="/api/v1/payments", tags=["Payments"])
app.include_router(checkin.router, prefix="/api/v1/checkin", tags=["Check-in"])
app.include_router(announcements.router, prefix="/api/v1/announcements", tags=["Announcements"])
app.include_router(staff.router, prefix="/api/v1/staff", tags=["Staff"])
