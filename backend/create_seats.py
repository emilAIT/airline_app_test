#!/usr/bin/env python3
"""
Скрипт для создания мест в самолете.
Подключится к БД и создаст 60 мест для самолета ID=1
(10 рядов по 6 мест: A, B, C, D, E, F)
"""

import sys
import os
from pathlib import Path

# Добавить backend папку в path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.seat import Seat
from app.models.airplane import Airplane

# Подключение к БД
db_path = backend_dir / "app" / "zaku.db"
engine = create_engine(f"sqlite:///{db_path}")
Session = sessionmaker(bind=engine)
db = Session()

try:
    # Проверка что самолет существует
    airplane = db.query(Airplane).filter(Airplane.id == 1).first()
    if not airplane:
        print("❌ Самолет с ID=1 не найден!")
        exit(1)
    
    print(f"✅ Найден самолет: {airplane.registration_number} ({airplane.model})")
    
    # Удаление старых мест если есть
    old_seats = db.query(Seat).filter(Seat.airplane_id == 1).all()
    if old_seats:
        print(f"🗑️  Удаляю {len(old_seats)} старых мест...")
        for seat in old_seats:
            db.delete(seat)
        db.commit()
    
    # Создание новых мест
    seats = []
    seat_letters = ['A', 'B', 'C', 'D', 'E', 'F']
    
    for row in range(1, 11):  # 10 рядов
        for letter in seat_letters:
            seat = Seat(
                airplane_id=1,
                row_number=row,
                seat_letter=letter,
                category='extra_legroom' if row <= 3 else 'standard'
            )
            seats.append(seat)
    
    # Сохранение в БД
    db.add_all(seats)
    db.commit()
    
    print(f"✅ Создано {len(seats)} мест:")
    print(f"   - Ряды 1-3: Extra Legroom (18 мест)")
    print(f"   - Ряды 4-10: Standard (42 места)")
    print(f"\nВсего: 60 мест")
    
except Exception as e:
    print(f"❌ Ошибка: {e}")
    db.rollback()
finally:
    db.close()
