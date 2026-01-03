YOUTUBE:
https://youtu.be/2yLB3MRZwpM

# Airline Mini-System

Полнофункциональная система авиакомпании с FastAPI backend и Flutter frontend.

## Особенности

### Backend (FastAPI)
- ✅ RESTful API
- ✅ JWT аутентификация
- ✅ SQLite база данных
- ✅ Роли пользователей (Passenger, Staff)
- ✅ Бронирование рейсов
- ✅ Управление рейсами и самолетами
- ✅ Check-in и посадочные талоны
- ✅ Система объявлений
- ✅ Mock оплата

### Frontend (Flutter)
- ✅ Современный и красивый UI
- ✅ Полная интеграция с backend
- ✅ Поиск рейсов
- ✅ Бронирование с выбором мест
- ✅ Check-in и QR коды
- ✅ Управление профилем

## Структура проекта

```
backend2/
├── app/                    # Backend (FastAPI)
│   ├── core/              # Конфигурация, БД, безопасность
│   ├── models/            # SQLAlchemy модели
│   ├── routers/           # API endpoints
│   └── schemas/           # Pydantic схемы
├── frontend/              # Frontend (Flutter)
│   ├── lib/
│   │   ├── config/        # Конфигурация API
│   │   ├── core/          # Тема
│   │   ├── models/        # Модели данных
│   │   ├── services/      # API сервисы
│   │   ├── providers/     # State management
│   │   └── screens/       # Экраны приложения
│   └── pubspec.yaml
└── README.md
```

## Установка и запуск

### Backend

1. Убедитесь, что вы находитесь в корневой директории проекта (`backend2`), а не в `app`

2. Установите зависимости:

```bash
pip install -r requirements.txt
```

3. Запустите сервер (из корневой директории `backend2`):

```bash
python -m uvicorn app.main:app --reload
```

**Важно**: Запускайте из корневой директории проекта, не из `app/`!

Backend будет доступен по адресу: `http://localhost:8000`

API документация (Swagger): `http://localhost:8000/docs`

### Frontend

1. Установите Flutter SDK (если еще не установлен):
   - Следуйте инструкциям на https://flutter.dev/docs/get-started/install

2. Перейдите в директорию frontend:

```bash
cd frontend
```

3. Установите зависимости:

```bash
flutter pub get
```

4. Настройте API URL (при необходимости):

Отредактируйте `frontend/lib/config/api_config.dart`:

- Для iOS Simulator/macOS: `http://localhost:8000/api/v1` ✅ (по умолчанию)
- Для Android Emulator: `http://10.0.2.2:8000/api/v1`
- Для физического устройства: `http://YOUR_IP_ADDRESS:8000/api/v1`

5. Запустите приложение:

```bash
flutter run
```

## Первое использование

1. **Запустите backend** (см. выше)

2. **Запустите frontend** (см. выше)

### Для пассажиров (Passengers):

3. **Зарегистрируйтесь** в приложении:
   - Email и пароль
   - Имя (опционально)
   - ⚠️ Все новые пользователи автоматически регистрируются как **Passenger**

4. **Заполните профиль**:
   - Телефон
   - Номер паспорта
   - Национальность
   - Дата рождения

   ⚠️ **Важно**: Профиль должен быть полностью заполнен перед бронированием рейсов!

5. **Создайте тестовые данные** (опционально):

Если у вас нет данных в базе, используйте скрипт `seed_data.py` для создания тестовых рейсов, аэропортов и самолетов.

### Для сотрудников (Staff):

**⚠️ В системе есть только один предопределенный Staff пользователь:**

- **Email:** `staff@airline.com`
- **Password:** `admin123`

Staff пользователь создается автоматически при первом запуске backend.

Для входа как Staff:
1. Используйте Swagger UI: http://localhost:8000/docs
2. Endpoint: `/api/v1/auth/login/access-token`
3. Укажите email и пароль выше
4. Используйте полученный токен для доступа к Staff endpoints

⚠️ **ВАЖНО:** Измените пароль Staff в production! (см. `STAFF_CREDENTIALS.md`)

Подробная информация: см. `STAFF_CREDENTIALS.md` и `STAFF_QUICK_START.md`

## Основные функции

### Для пассажиров:
- 🔍 Поиск рейсов по маршруту и дате
- 📅 Просмотр деталей рейса
- 💺 Бронирование с выбором мест
- 💳 Оплата бронирования (mock)
- ✈️ Check-in (доступен за 24-1 час до вылета)
- 🎫 Посадочные талоны с QR-кодами
- 📋 Просмотр бронирований
- 👤 Управление профилем

### Для сотрудников (Staff):
- Управление аэропортами и самолетами
- Создание и обновление рейсов
- Управление бронированиями
- Создание объявлений для рейсов

## Технологии

### Backend:
- FastAPI
- SQLAlchemy
- Pydantic
- JWT (python-jose)
- SQLite

### Frontend:
- Flutter
- Riverpod (State Management)
- Dio (HTTP Client)
- Shared Preferences
- QR Flutter

## API Endpoints

Основные endpoints доступны по префиксу `/api/v1`:

- `/auth/register` - Регистрация
- `/auth/login/access-token` - Вход
- `/users/me` - Текущий пользователь
- `/users/me/profile` - Обновление профиля
- `/flights/search` - Поиск рейсов
- `/flights/{id}` - Детали рейса
- `/flights/{id}/seats` - Схема мест
- `/bookings` - Создание бронирования
- `/bookings/me` - Мои бронирования
- `/bookings/{id}/pay` - Оплата
- `/checkin/{id}/checkin` - Check-in
- `/checkin/{id}/boarding-pass` - Посадочный талон

Полная документация API доступна по адресу `/docs` после запуска backend.


