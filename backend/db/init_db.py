from datetime import datetime
from sqlalchemy.orm import Session

from db.session import engine, SessionLocal
from db.base import Base
from models.user import User
from models.flight import Flight
from models.airport import Airport

from core.security import hash_password
from core.config import settings


def init_db():
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    try:
        # ---------- ADMIN ----------
        admin = db.query(User).filter(
            User.email == settings.ADMIN_EMAIL
        ).first()

        if not admin:
            admin = User(
                email=settings.ADMIN_EMAIL,
                hashed_password=hash_password(settings.ADMIN_PASSWORD),
                role="ADMIN",
                is_active=True,
            )
            db.add(admin)
        # ---------- AIRPORTS ----------
        airports = [
            ("IST", "Istanbul Airport", "Istanbul", "Turkey"),
            ("DXB", "Dubai International", "Dubai", "UAE"),
            ("LHR", "Heathrow", "London", "UK"),
        ]

        for code, name, city, country in airports:
            exists = db.query(Airport).filter(
                Airport.code == code
            ).first()
            if not exists:
                db.add(
                    Airport(
                        code=code,
                        name=name,
                        city=city,
                        country=country,
                    )
                )

        db.commit()

        flights = [
            {
                "flight_number": "TK101",
                "origin_code": "IST",
                "destination_code": "DXB",
                "departure_time": datetime(2026, 1, 10, 8, 00),
                "arrival_time": datetime(2026, 1, 10, 13, 30),
                "price": 450.0,
                "status": "SCHEDULED",
            },
            {
                "flight_number": "EK202",
                "origin_code": "DXB",
                "destination_code": "LHR",
                "departure_time": datetime(2026, 1, 11, 2, 15),
                "arrival_time": datetime(2026, 1, 11, 7, 45),
                "price": 720.0,
                "status": "SCHEDULED",
            },
            {
                "flight_number": "BA303",
                "origin_code": "LHR",
                "destination_code": "IST",
                "departure_time": datetime(2026, 1, 12, 18, 00),
                "arrival_time": datetime(2026, 1, 12, 23, 20),
                "price": 510.0,
                "status": "SCHEDULED",
            },
        ]

        for flight_data in flights:
            exists = db.query(Flight).filter(
                Flight.flight_number == flight_data["flight_number"]
            ).first()

            if exists:
                continue

            db.add(
                Flight(
                    flight_number=flight_data["flight_number"],
                    origin_code=flight_data["origin_code"],
                    destination_code=flight_data["destination_code"],
                    departure_time=flight_data["departure_time"],
                    arrival_time=flight_data["arrival_time"],
                    price=flight_data["price"],
                    status=flight_data["status"],
                )
            )

        db.commit()

    except Exception as e:
        db.rollback()
        raise e

    finally:
        db.close()


if __name__ == "__main__":
    init_db()
