from sqlalchemy import Column, Integer, String, Date, ForeignKey
from sqlalchemy.orm import relationship

from db.base import Base


class PassengerProfile(Base):
    __tablename__ = "passenger_profiles"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    passport_number = Column(String, nullable=True)
    nationality = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)

    # 🔗 связь обратно к User
    user = relationship(
        "User",
        back_populates="profile",
    )
