import logging

from sqlmodel import Session, select

from app.core.config import settings
from app.db import engine
from app.core.security import get_password_hash
from app.models import User, UserRole

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def init() -> None:
    with Session(engine) as session:
        # проверяем, существует ли STAFF
        statement = select(User).where(
            User.email == settings.FIRST_SUPERUSER
        )
        user = session.exec(statement).first()

        if user:
            logger.info("Initial staff user already exists")
            return

        logger.info("Creating initial staff user")

        user = User(
            email=settings.FIRST_SUPERUSER,
            full_name="Initial Staff User",
            hashed_password=get_password_hash(
                settings.FIRST_SUPERUSER_PASSWORD
            ),
            is_active=True,
            role=UserRole.STAFF,
        )

        session.add(user)
        session.commit()
        session.refresh(user)  # Refresh to get the generated ID
        
        logger.info(f"Created initial staff user with ID: {user.id}, Email: {user.email}")


def main() -> None:
    logger.info("Creating initial data")
    init()
    logger.info("Initial data created")


# if __name__ == "__main__":
#     main()

if __name__ == "__main__":
    pass

