from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.routers import auth, passenger, staff

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Airline Booking & Operations System API",
    version="1.0.0"
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
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(passenger.router, prefix=settings.API_V1_PREFIX)
app.include_router(staff.router, prefix=settings.API_V1_PREFIX)


@app.get("/")
def root():
    return {
        "message": "Welcome to Airline Booking & Operations System API",
        "docs": "/docs",
        "api_prefix": settings.API_V1_PREFIX
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.get("/favicon.ico")
def favicon():
    """Handle favicon requests to avoid 404 errors"""
    from fastapi.responses import Response
    return Response(status_code=204)  # No Content

