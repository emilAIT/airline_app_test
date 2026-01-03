import os


class Settings:
    PROJECT_NAME: str = "Airline Exam System"
    PROJECT_VERSION: str = "1.0.0"

    # Секретный ключ. Сгенерируй нормальный через openssl rand -hex 32, но пока держи этот
    SECRET_KEY: str = "super_secret_exam_key_do_not_use_in_prod_bro"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # Сутки кайфуем

    DATABASE_URL: str = "sqlite:///./airline.db"

    # Stripe Configuration
    STRIPE_SECRET_KEY: str = "sk_test_51SjklxPf3XqYjjAphV2J914VHvnvUqZvqFxS9BUiXphwtSjQCu2zLUBGBcKotQEvFYGDQAmiX1tPENQa9ORVDYXO00DZPgZInb"
    STRIPE_PUBLISHABLE_KEY: str = "pk_test_51SjklxPf3XqYjjApNTK7Fm5C1QTH6udcsIFYc2F8s6NHRkg8bceLiu8Gxj8skCFdH1v4t1uctkbQDYC92asogCDr00rX0pQn6i"


settings = Settings()
