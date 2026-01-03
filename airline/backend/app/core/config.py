# Импортируем BaseSettings из Pydantic v2 для работы с настройками приложения
from pydantic_settings import BaseSettings
# Optional используется для значений, которые могут быть None
from typing import Optional

# Создаём класс Settings для хранения всех настроек нашего приложения
class Settings(BaseSettings):
    # Секретный ключ для шифрования (например, JWT токенов)
    # В продакшене обязательно менять на настоящий секрет
    SECRET_KEY: str = "your-secret-key-here-change-in-production-12345"
    
    # Алгоритм шифрования для токенов (JWT)
    ALGORITHM: str = "HS256"
    
    # Время жизни токена в минутах (Access Token)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Время жизни Refresh токена в днях
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # URL базы данных. Здесь используется SQLite с файлом airline.db
    DATABASE_URL: str = "sqlite:///./airline.db"
    
    # Внутренний класс Config настраивает поведение BaseSettings
    class Config:
        # Если есть файл .env, настройки можно подгружать из него
        env_file = ".env"
        # Переменные окружения будут чувствительны к регистру
        case_sensitive = True

# Создаём экземпляр настроек
# Теперь можно использовать settings.SECRET_KEY, settings.DATABASE_URL и т.д.
settings = Settings()

# Проверка, что всё работает
if __name__ == "__main__":
    print("Секретный ключ:", settings.SECRET_KEY)
    print("Алгоритм:", settings.ALGORITHM)
    print("Время жизни токена (минуты):", settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    print("URL базы данных:", settings.DATABASE_URL)


