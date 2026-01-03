from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from db.session import engine
from db.base import Base

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Airline Booking & Operations System",
    version="1.0.0"
)

origins = [
    # Web / desktop
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://0.0.0.0:8080",
    "http://localhost",
    "http://127.0.0.1",
    "localhost:8080",
    "127.0.0.1:8080",

    # Android Emulator (AVD)
    "http://10.0.2.2",
    "http://10.0.2.2:8000",

    # Genymotion
    "http://10.0.3.2",
    "http://10.0.3.2:8000",

    # iOS Simulator (работает как localhost)
    "http://localhost:8000",
]
# 2. Add the middleware to your app instance
from fastapi import Request

@app.middleware("http")
async def log_origin(request: Request, call_next):
    origin = request.headers.get("origin")
    method = request.method
    path = request.url.path
    if origin:
        print(f"Request: {method} {path} from origin: {origin}")
    else:
        print(f"Request: {method} {path} (No Origin)")
    response = await call_next(request)
    return response

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print(f"GLOBAL ERROR: {exc}")
    # We return a response with CORS headers manually to ensure the browser sees the error
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal Server Error", "message": str(exc)},
        headers={
            "Access-Control-Allow-Origin": request.headers.get("origin", "*"),
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "*",
            "Access-Control-Allow-Headers": "*",
        }
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from api.routes.flights import router as flights_router
from api.routes.auth import router as auth_router
from api.routes.me import router as me_router
from api.routes.airports import router as airports_router
from api.routes.bookings import router as bookings_router
from api.routes.payments import router as payments_router
from api.routes.checkin import router as checkin_router
from api.routes.admin import router as admin_router
from api.routes.announcements import router as announcements_router

app.include_router(flights_router)
app.include_router(me_router)
app.include_router(auth_router)
app.include_router(airports_router)
app.include_router(bookings_router)
app.include_router(payments_router)
app.include_router(checkin_router)
app.include_router(admin_router)
app.include_router(announcements_router)

@app.get("/")
def root():
    return {"message": "Welcome to Airline Booking API. Go to /docs for API documentation."}
