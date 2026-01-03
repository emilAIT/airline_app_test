# from sqlalchemy.orm import Session
# from fastapi import HTTPException

# from models.payment import Payment
# from models.booking import Booking


# class PaymentService:

#     @staticmethod
#     def pay(
#         db: Session,
#         booking: Booking,
#         method: str,
#         amount: float,
#     ) -> Payment:
#         if booking.status == "CONFIRMED":
#             raise HTTPException(400, "Booking already paid")

#         payment = Payment(
#             booking_id=booking.id,
#             method=method,
#             amount=amount,
#             status="PAID",  # MOCK
#         )

#         booking.status = "CONFIRMED"

#         db.add(payment)
#         db.commit()
#         db.refresh(payment)
#         return payment
