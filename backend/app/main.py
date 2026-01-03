from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, flights, airports, bookings, payments, checkin, announcements, staff

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Airline Booking & Operations System",
    description="FastAPI backend for airline booking system",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(airports.router)
app.include_router(flights.router)
app.include_router(bookings.router)
app.include_router(payments.router)
app.include_router(checkin.router)
app.include_router(announcements.router)
app.include_router(staff.router)


@app.get("/")
def root():
    return {
        "message": "Airline Booking & Operations System API",
        "docs": "/docs",
        "version": "1.0.0"
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}

