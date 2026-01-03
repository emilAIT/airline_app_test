# 🔥 HARD RESET - Инструкция по запуску

## Что было исправлено:

### Backend Models:
✅ Seat модель - привязана к airplane_id, имеет row_number, seat_letter, category
✅ Ticket.seat - relationship с back_populates
✅ Airplane.seats - relationship добавлена

### Backend Schemas:
✅ FlightCreateRequest - status с Field(default="SCHEDULED")
✅ TicketInfo - добавлен Optional[SeatInfo] для вложенных данных seat
✅ SeatInfo - новая схема для отображения места (row_number, seat_letter, category)

### Backend Repositories:
✅ BookingRepository - добавлен joinedload(Ticket.seat) во всех методах

### Frontend:
✅ API Service - улучшен debug output (📤 Request body, ✅/❌ результаты)
✅ trip_details_screen.dart - отображает seat.row_number + seat.seat_letter + category

### Seed Script:
✅ seed_full.py - создает 3 аэропорта, 1 самолет Boeing 737, автогенерация 60 мест (10 рядов x 6 мест)

---

## 🚀 Шаги запуска:

### 1. Остановите backend и удалите базу данных:
```powershell
# В терминале backend (Ctrl+C для остановки)
# Затем удалите файл базы:
Remove-Item C:\Users\zarak\Documents\booking_app\backend\zaku.db -ErrorAction SilentlyContinue
```

### 2. Запустите Full Seed:
```powershell
cd C:\Users\zarak\Documents\booking_app\backend
.\.venv\Scripts\python seed_full.py
```

Вы должны увидеть:
```
🔄 Starting Full Seed...
⚠️  Dropping all tables...
🏗️  Creating all tables...
✅ Created 3 airports: ALA, DEL, CIT
✅ Created airplane: Boeing 737-800 (ID: 1)
✅ Created 60 seats (rows 1-3: extra_legroom, rows 4-10: standard)
✅ Created users: staff@zaku.kz, passenger@zaku.kz

✅ Full seed completed successfully!

📊 Database summary:
   - Airports: 3
   - Airplanes: 1
   - Seats: 60
   - Users: 2
```

### 3. Запустите backend:
```powershell
cd C:\Users\zarak\Documents\booking_app\backend
.\.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Hot Restart Flutter:
В терминале с Flutter нажмите **R** (заглавная буква)

---

## 🧪 Тестирование:

### 1. Войдите как STAFF:
- Email: `staff@zaku.kz`
- Password: `staff123`

### 2. Создайте рейс:
- Flight Number: KISS
- Origin: ALA (Almaty)
- Destination: DEL (Delhi)
- Airplane: Boeing 737-800 (UP-B7701)
- Departure/Arrival: любые даты/времена
- Price: 50000
- Terminal: A
- Gate: 12

### 3. Проверьте консоль Flutter:
Вы должны увидеть:
```
📤 Request body: {"flight_number":"KISS","origin_id":1,"destination_id":2,"departure_time":"2026-01-03T04:08:00.000","arrival_time":"2026-01-03T07:08:00.000","price":50000.0,"airplane_id":1,"terminal":"A","gate":"12"}
✅ Flight created successfully
```

### 4. Войдите как PASSENGER и забронируйте:
- Email: `passenger@zaku.kz`
- Password: `passenger123`
- Выберите созданный рейс
- Выберите места (например, 1A - extra_legroom)
- Завершите бронирование

### 5. Проверьте отображение билета:
В разделе "Мои поездки" вы должны увидеть:
```
Место: 1A (Extra Legroom)
```

---

## ✅ Критические проверки:

### Backend должен запуститься без ошибок:
- ✅ Database initialized
- ✅ Application startup complete

### Frontend должен показать:
- ✅ 📤 Request body с правильными int значениями
- ✅ ✅ Flight created successfully
- ✅ Seat отображается как "1A (Extra Legroom)"

### Если ошибка 500:
1. Проверьте логи backend - должно быть видно SQL запросы
2. Убедитесь что таблица seats существует
3. Убедитесь что в таблице seats есть записи для airplane_id=1

### Если ошибка 422:
1. Проверьте Flutter console - должно быть видно точный JSON
2. Убедитесь что все ID передаются как int (не String)
3. Убедитесь что status не передается (используется default)

---

## 🎯 Результат:

После успешного запуска вы должны иметь:
- ✅ 3 аэропорта (ALA, DEL, CIT)
- ✅ 1 самолет Boeing 737 с 60 местами
- ✅ Возможность создавать рейсы через UI
- ✅ Отображение мест с категорией (Extra Legroom)
- ✅ Нет ошибок 500 или 422

Удачи! 🚀
