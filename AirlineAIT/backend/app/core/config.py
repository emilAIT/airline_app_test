"""
Application configuration settings.

Contains all environment-configurable settings including:
- Database connection URL
- JWT secret key and algorithm
- Admin default credentials

Uses Pydantic BaseSettings for .env file support.

Part of: Backend Core
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite:///./airline.db"
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    # Admin
    ADMIN_EMAIL: str = "admin@airline.com"
    ADMIN_PASSWORD: str = "admin123"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

