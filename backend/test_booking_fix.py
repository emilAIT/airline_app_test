from db.session import SessionLocal
from models.flight import Flight
from models.user import User
from models.booking import Booking
from models.seat_hold import SeatHold
from datetime import datetime, timedelta

def test_booking():
    db = SessionLocal()
    try:
        # 1. Get user
        user = db.query(User).filter(User.email == 'email@gmail.com').first()
        if not user:
            print("User not found")
            return
        
        # 2. Get flight
        flight = db.query(Flight).filter(Flight.id == 3).first()
        if not flight:
            print("Flight 3 not found")
            return
            
        print(f"Testing booking for user {user.email}, flight {flight.id}")
        
        # 3. Create a hold if not exists
        seat = "1A"
        hold = db.query(SeatHold).filter_by(flight_id=flight.id, seat_number=seat).first()
        if not hold:
            hold = SeatHold(
                flight_id=flight.id,
                seat_number=seat,
                user_id=user.id,
                expires_at=datetime.utcnow() + timedelta(minutes=10)
            )
            db.add(hold)
            db.commit()
            print(f"Created hold for seat {seat}")
        
        # 4. Try create booking
        ticket_data = [
            {
                "passenger_name": user.profile.full_name if user.profile else "Test Name",
                "seat_number": seat,
            }
        ]
        
        print("Calling Booking.create_booking...")
        booking = Booking.create_booking(
            db=db,
            flight=flight,
            ticket_data=ticket_data
        )
        print(f"Booking created successfully: {booking.pnr_code}")
        
    except Exception as e:
        import traceback
        print("ERROR DETECTED:")
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_booking()
