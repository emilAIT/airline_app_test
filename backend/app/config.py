"""
Application configuration using Pydantic Settings.
Loads from environment variables and .env file.
"""
from pathlib import Path
from typing import List

from pydantic_settings import BaseSettings


_BACKEND_DIR = Path(__file__).resolve().parents[1]  # backend/
_ENV_FILE = _BACKEND_DIR / ".env"
_DEFAULT_DB_FILE = _BACKEND_DIR / "zaku.db"


class Settings(BaseSettings):
    """Application settings loaded from environment."""
    
    # Application
    app_name: str = "ZaKu"
    debug: bool = True
    
    # Database
    # Use an absolute path so running from a different CWD doesn't create a
    # second DB somewhere else.
    database_url: str = f"sqlite:///{_DEFAULT_DB_FILE.as_posix()}"

    def model_post_init(self, __context) -> None:  # type: ignore[override]
        # If DATABASE_URL in .env is relative (e.g., sqlite:///./zaku.db),
        # normalize it to an absolute path under backend/.
        url = self.database_url
        if isinstance(url, str) and url.startswith("sqlite:///"):
            raw_path = url.removeprefix("sqlite:///")
            path = Path(raw_path)
            if not path.is_absolute():
                path = (_BACKEND_DIR / path).resolve()
                self.database_url = f"sqlite:///{path.as_posix()}"
    
    # Security - JWT configuration
    secret_key: str  # Must be set in .env, min 32 chars
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440  # 24 hours
    
    # CORS - allows Flutter app to connect during development
    allowed_origins: List[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*"
    ]
    
    # Business Logic
    seat_hold_duration_minutes: int = 10
    
    class Config:
        # Resolve relative to backend/ so uvicorn can be started from anywhere.
        env_file = str(_ENV_FILE)
        env_file_encoding = "utf-8"


# Global settings instance
settings = Settings()
