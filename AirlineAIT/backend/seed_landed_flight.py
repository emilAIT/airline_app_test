import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, configure_mappers
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# Add the current directory to sys.path to import app modules
sys.path.append(os.getcwd())

from app.db.base import Base
from app.models.flight import Flight, FlightStatus
from app.models.airport import Airport
from app.models.airplane import Airplane

# Ensure all mappers are configured
configure_mappers()

DATABASE_URL = "sqlite:///./airline.db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_landed_flight():
    db = SessionLocal()
    try:
        # Get airports and airplane
        airports = db.query(Airport).limit(3).all()
        airplane = db.query(Airplane).first()
        
        if len(airports) < 2 or not airplane:
            print("Error: Need at least 2 airports and 1 airplane.")
            return

        now = datetime.now(ZoneInfo("Asia/Bishkek")).replace(tzinfo=None, second=0, microsecond=0)
        flights_to_seed = [
            {"num": "LD123", "dept_offset": 5, "dur": 3},
            {"num": "LD124", "dept_offset": 8, "dur": 4},
        ]

        for f_data in flights_to_seed:
            existing = db.query(Flight).filter(Flight.flight_number == f_data["num"]).first()
            if existing:
                print(f"Flight {f_data['num']} already exists. Skipping.")
                continue

            # Pick different origin/dest indices to vary the data
            origin = airports[0]
            dest = airports[1]
            
            departure = now - timedelta(hours=f_data["dept_offset"])
            arrival = departure + timedelta(hours=f_data["dur"])
            
            base_price = 199.99 + (f_data["dept_offset"] * 10)
            flight = Flight(
                flight_number=f_data["num"],
                origin_airport_id=origin.id,
                destination_airport_id=dest.id,
                airplane_id=airplane.id,
                departure_time=departure,
                arrival_time=arrival,
                price=base_price,
                category_prices=f'{{"BUSINESS": {base_price * 3}, "EXTRA_LEGROOM": {base_price * 1.5}, "ECONOMY": {base_price}}}',
                status=FlightStatus.LANDED
            )
            db.add(flight)
            print(f"✓ Created Landed flight {f_data['num']}")
        
        db.commit()
        
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_landed_flight()
