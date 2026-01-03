from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Airline Mini-System"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "supersecretkeyneedschange" # TODO: Change in production
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8 # 8 days
    SQLALCHEMY_DATABASE_URI: str = "sqlite:///./sql_app.db"

    class Config:
        env_file = ".env"

settings = Settings()
