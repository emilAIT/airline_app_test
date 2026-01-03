from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # ---------- APP ----------
    APP_NAME: str = "Airline Booking System"
    DEBUG: bool = True

    # ---------- DATABASE ----------
    DATABASE_URL: str

    # ---------- SECURITY / JWT ----------
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24

    # ---------- ADMIN ----------
    ADMIN_EMAIL: str
    ADMIN_PASSWORD: str

    # ---------- CORS ----------
    CORS_ORIGINS: list[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://127.0.0.1:8000",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )


settings = Settings()
