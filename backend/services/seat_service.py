# from datetime import datetime, timedelta
# from sqlalchemy.orm import Session
# from fastapi import HTTPException

# # В реальности тут будет Seat / SeatHold модель
# # Сейчас — экзаменационный MOCK

# SEAT_HOLD_MINUTES = 10


# class SeatService:

#     @staticmethod
#     def hold_seat(
#         seat_number: str,
#     ):
#         return {
#             "seat": seat_number,
#             "hold_until": datetime.utcnow() + timedelta(minutes=SEAT_HOLD_MINUTES),
#         }

#     @staticmethod
#     def validate_seat_available(
#         seat_number: str,
#     ):
#         # Заглушка под конкурентность
#         return True
