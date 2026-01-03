from app.database import SessionLocal
from app.models import Booking

db = SessionLocal()
booking = db.query(Booking).first()
if booking:
    print(f'Booking PNR: {booking.pnr}')
    if booking.flight:
        print(f'Flight: {booking.flight.flight_number}')
        print(f'Airplane: {booking.flight.airplane.model if booking.flight.airplane else "No airplane assigned"}')
    print('SUCCESS: Bookings load correctly!')
else:
    print('No bookings found')
