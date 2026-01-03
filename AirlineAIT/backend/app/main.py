"""
Main FastAPI application entry point.

This file initializes the FastAPI app with:
- CORS middleware for cross-origin requests
- Background task for booking expiration cleanup (runs every 60s)
- Custom exception handlers with CORS headers
- All API routers mounted under /api prefix

Part of: Backend Core
"""
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.main import api_router
from app.db.session import engine
from app.db.base import Base
from app.core.config import settings
from app.models import * # Import all models to register them with Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Airline Booking & Operations API",
    description="Backend API for Airline Booking System",
    version="1.0.0"
)

# Background tasks
import asyncio
from app.db.session import SessionLocal

async def booking_cleanup_loop():
    """Background task to cancel expired bookings"""
    while True:
        try:
            # Create a new session for this operation
            db = SessionLocal()
            from app.services.booking import cancel_expired_bookings
            cancel_expired_bookings(db)
            db.close()
        except Exception as e:
            print(f"Error in booking cleanup loop: {e}")
        
        # Run every 60 seconds
        await asyncio.sleep(60)

@app.on_event("startup")
async def startup_event():
    # Start background task
    asyncio.create_task(booking_cleanup_loop())

# CORS middleware - add before routes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Custom exception handler to ensure CORS headers on errors
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
            "Access-Control-Allow-Headers": "*",
        },
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
            "Access-Control-Allow-Headers": "*",
        },
    )

# Include API routes
app.include_router(api_router, prefix="/api")


@app.get("/")
def root():
    return {
        "message": "Airline Booking & Operations API",
        "docs": "/docs",
        "version": "1.0.0"
    }


@app.get("/health")
def health_check():
    return {"status": "ok"}

