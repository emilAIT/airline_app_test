from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# check_same_thread=False нужен только для SQLite, не забудь
engine = create_engine(
    settings.DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency для инъекции сессии в роуты


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
