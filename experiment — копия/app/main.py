from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from app.routers import auth, users, staff, flights, bookings, checkin
from app.core.database import engine, Base
from app.core.database import SessionLocal
from app.core import security
from app.models import user as user_model

# Create tables
Base.metadata.create_all(bind=engine)

# Fix payments table schema if needed (for existing databases)
from sqlalchemy import text
try:
    with engine.begin() as conn:  # Use begin() for automatic transaction handling
        result = conn.execute(text("PRAGMA table_info(payments)"))
        columns = [row[1] for row in result.fetchall()]
        if 'method' not in columns:
            # SQLite: ALTER TABLE ADD COLUMN
            conn.execute(text("ALTER TABLE payments ADD COLUMN method VARCHAR(20)"))
            # Set default value for existing rows
            conn.execute(text("UPDATE payments SET method = 'CARD' WHERE method IS NULL"))
            print("Fixed payments table schema - added method column")
except Exception as e:
    # Table might not exist yet, which is fine
    pass

# Fix tickets table schema - add passport_number column if needed
try:
    with engine.begin() as conn:
        result = conn.execute(text("PRAGMA table_info(tickets)"))
        columns = [row[1] for row in result.fetchall()]
        if 'passport_number' not in columns:
            conn.execute(text("ALTER TABLE tickets ADD COLUMN passport_number VARCHAR(50)"))
            print("Fixed tickets table schema - added passport_number column")
except Exception as e:
    # Table might not exist yet, which is fine
    pass

# Create default Staff user if it doesn't exist


def create_default_staff():
    """Создает предопределенного Staff пользователя при старте приложения"""
    STAFF_EMAIL = "admin@airline.com"
    STAFF_PASSWORD = "admin123"  # ⚠️ Измените пароль в production!
    STAFF_FULL_NAME = "System Administrator"

    db = SessionLocal()
    try:
        # Проверяем, существует ли уже Staff пользователь
        existing_staff = db.query(user_model.User).filter(
            user_model.User.role == user_model.UserRole.STAFF
        ).first()

        if existing_staff:
            return

        # Проверяем, существует ли пользователь с таким email
        existing_user = db.query(user_model.User).filter(
            user_model.User.email == STAFF_EMAIL
        ).first()

        if existing_user:
            # Обновляем роль на STAFF и гарантируем, что пользователь активен
            existing_user.role = user_model.UserRole.STAFF
            existing_user.hashed_password = security.get_password_hash(
                STAFF_PASSWORD)
            existing_user.full_name = STAFF_FULL_NAME
            existing_user.is_active = True  # Гарантируем, что пользователь активен
            db.commit()
            return

        # Создаем нового Staff пользователя
        staff_user = user_model.User(
            email=STAFF_EMAIL,
            hashed_password=security.get_password_hash(STAFF_PASSWORD),
            full_name=STAFF_FULL_NAME,
            role=user_model.UserRole.STAFF,
            is_active=True,
        )
        db.add(staff_user)
        db.commit()
    except Exception:
        db.rollback()
    finally:
        db.close()


# Создаем Staff пользователя при старте
create_default_staff()

# Fix announcements table schema - add user_id column if needed
try:
    with engine.begin() as conn:
        result = conn.execute(text("PRAGMA table_info(announcements)"))
        columns = [row[1] for row in result.fetchall()]
        if 'user_id' not in columns:
            conn.execute(text("ALTER TABLE announcements ADD COLUMN user_id INTEGER"))
            conn.execute(text("CREATE INDEX IF NOT EXISTS ix_announcements_user_id ON announcements(user_id)"))
            print("Fixed announcements table schema - added user_id column")
except Exception as e:
    # Table might not exist yet, which is fine
    pass

# Create user_notifications table if it doesn't exist
try:
    with engine.begin() as conn:
        result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table' AND name='user_notifications'"))
        if result.fetchone() is None:
            # Table doesn't exist, create it
            conn.execute(text("""
                CREATE TABLE user_notifications (
                    id INTEGER NOT NULL PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    type VARCHAR(50) NOT NULL,
                    message VARCHAR NOT NULL,
                    created_at DATETIME NOT NULL,
                    is_read BOOLEAN NOT NULL DEFAULT 0,
                    FOREIGN KEY(user_id) REFERENCES users (id)
                )
            """))
            conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_notifications_id ON user_notifications(id)"))
            conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_notifications_user_id ON user_notifications(user_id)"))
            print("Created user_notifications table")
        else:
            # Table exists, check if is_read column exists
            result = conn.execute(text("PRAGMA table_info(user_notifications)"))
            columns = [row[1] for row in result.fetchall()]
            if 'is_read' not in columns:
                conn.execute(text("ALTER TABLE user_notifications ADD COLUMN is_read BOOLEAN NOT NULL DEFAULT 0"))
                print("Fixed user_notifications table schema - added is_read column")
except Exception as e:
    print(f"Error creating/fixing user_notifications table: {e}")
    pass

app = FastAPI(
    title="Airline Mini-System API",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware for Flutter frontend
# Allow all origins for development (Flutter web uses dynamic ports)
# Note: Cannot use allow_credentials=True with allow_origins=["*"]
# IMPORTANT: CORS middleware must be added BEFORE routers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(staff.router, prefix="/api/v1/staff", tags=["staff"])
app.include_router(flights.router, prefix="/api/v1/flights", tags=["flights"])
app.include_router(
    bookings.router, prefix="/api/v1/bookings", tags=["bookings"])
app.include_router(checkin.router, prefix="/api/v1/checkin", tags=["checkin"])


@app.middleware("http")
async def add_cors_header(request: Request, call_next):
    """Add CORS headers to all responses, including errors"""
    try:
        response = await call_next(request)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Access-Control-Expose-Headers"] = "*"
        return response
    except Exception as e:
        # Handle exceptions and add CORS headers
        import traceback
        traceback.print_exc()
        response = JSONResponse(
            status_code=500,
            content={"detail": f"Internal server error: {str(e)}"},
        )
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Access-Control-Expose-Headers"] = "*"
        return response


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTP exceptions and ensure CORS headers are included"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "*",
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle all exceptions and ensure CORS headers are included"""
    import traceback
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": f"Internal server error: {str(exc)}"},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "*",
        },
    )


@app.get("/")
def root():
    return {"message": "Welcome to Airline Mini-System API"}

