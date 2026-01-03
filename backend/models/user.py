from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from db.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    role = Column(
        String,
        default="PASSENGER",
        nullable=False
    )  # PASSENGER | STAFF | ADMIN

    is_active = Column(Boolean, default=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    profile = relationship(
        "PassengerProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    # -------- role helpers --------

    def is_passenger(self) -> bool:
        return self.role == "PASSENGER"

    def is_staff(self) -> bool:
        return self.role in ("STAFF", "ADMIN")

    def is_admin(self) -> bool:
        return self.role == "ADMIN"

    # -------- status helpers --------

    def deactivate(self):
        self.is_active = False

    def activate(self):
        self.is_active = True

    # -------- password --------

    def set_password(self, hashed_password: str):
        self.hashed_password = hashed_password

    # -------- serialization --------

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "role": self.role,
            "is_active": self.is_active,
            "created_at": self.created_at,
        }

    # -------- factories --------

    @classmethod
    def create_staff(
        cls,
        db,
        email: str,
        hashed_password: str,
    ):
        user = cls(
            email=email,
            hashed_password=hashed_password,
            role="STAFF",
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user