"""Airport model (exam schema).

Fields:
    - id
    - code (IATA)
    - name
    - city
"""

from sqlalchemy import Column, Integer, String

from app.database import Base


class Airport(Base):
        __tablename__ = "airports"

        id = Column(Integer, primary_key=True, index=True, autoincrement=True)
        code = Column(String(3), unique=True, nullable=False, index=True)
        name = Column(String(255), nullable=False)
        city = Column(String(100), nullable=False)

        def __repr__(self) -> str:
                return f"<Airport(code='{self.code}', city='{self.city}')>"
