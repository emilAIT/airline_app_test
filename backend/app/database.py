"""
Database configuration and session management.
Uses SQLAlchemy 2.0 modern style with async support potential.
"""
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

# Create SQLAlchemy engine
# SQLite specific: check_same_thread=False needed for FastAPI
engine = create_engine(
    settings.database_url,
    connect_args={"check_same_thread": False},  # Only for SQLite
    echo=settings.debug  # Log SQL queries when debug=True
)

# Session factory
# autocommit=False: we manage transactions explicitly
# autoflush=False: we control when to flush to DB
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base class for all SQLAlchemy models
Base = declarative_base()


def get_db():
    """
    Dependency for FastAPI routes to get database session.
    
    Usage:
        @router.get("/something")
        def endpoint(db: Session = Depends(get_db)):
            ...
    
    Ensures session is closed after request completes.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    Initialize database - create all tables.
    Called on application startup.
    
    In production, use Alembic migrations instead.
    """
    # Ensure SQLAlchemy models are imported/registered with Base.metadata.
    # This is important when running scripts (seed/reset) outside FastAPI.
    import app.models  # noqa: F401

    Base.metadata.create_all(bind=engine)

    # Lightweight SQLite migration (no Alembic in this project).
    # Ensures new nullable columns can be added without deleting existing DB.
    if str(settings.database_url).startswith("sqlite"):
        with engine.begin() as conn:
            cols = conn.execute(text("PRAGMA table_info(flights)"))
            existing = {row[1] for row in cols.fetchall()}  # row[1] = name
            if "terminal" not in existing:
                conn.execute(text("ALTER TABLE flights ADD COLUMN terminal VARCHAR(10)"))
            if "gate" not in existing:
                conn.execute(text("ALTER TABLE flights ADD COLUMN gate VARCHAR(10)"))
