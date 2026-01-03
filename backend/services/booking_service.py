# import uuid
# from sqlalchemy.orm import Session
# from fastapi import HTTPException

# from models.booking import Booking
# from models.flight import Flight


# class BookingService:

#     @staticmethod
#     def create_booking(
#         db: Session,
#         user_id: int,
#         flight_id: int,
#     ) -> Booking:
#         flight = db.query(Flight).filter(Flight.id == flight_id).first()
#         if not flight:
#             raise HTTPException(404, "Flight not found")

#         if flight.status in ("CANCELLED", "DEPARTED"):
#             raise HTTPException(400, "Cannot book this flight")

#         booking = Booking(
#             pnr=str(uuid.uuid4())[:6].upper(),
#             user_id=user_id,
#             flight_id=flight_id,
#             status="CREATED",
#         )

#         db.add(booking)
#         db.commit()
#         db.refresh(booking)
#         return booking

#     @staticmethod
#     def cancel_booking(
#         db: Session,
#         booking: Booking,
#     ):
#         if booking.status == "CONFIRMED":
#             raise HTTPException(400, "Confirmed booking cannot be cancelled")

#         booking.status = "CANCELLED"
#         db.commit()
