# Flutter Airline App

Мобильное приложение для авиакомпании на Flutter, интегрированное с FastAPI бэкендом.

## Возможности

- 🔐 Авторизация и регистрация пользователей
- ✈️ Поиск рейсов по аэропортам и датам
- 🎫 Создание бронирований
- 💳 Оплата билетов (Card, Apple Pay, Google Pay)
- 📋 Просмотр и управление бронированиями
- 👤 Профиль пользователя

## Технологии

- **Flutter** - фреймворк для разработки
- **Stacked** - архитектура MVVM
- **HTTP** - для API запросов
- **JSON Serialization** - для работы с данными
- **SharedPreferences** - для хранения токенов

## Требования

- Flutter SDK >=3.0.3
- Dart SDK >=3.0.3
- Запущенный бэкенд на `localhost:8000`

## Установка и запуск

1. Установите зависимости:
```bash
flutter pub get
```

2. Сгенерируйте файлы (JSON сериализация, Stacked роутинг):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Запустите приложение:
```bash
flutter run
```

## Структура проекта

```
lib/
├── app/                    # Конфигурация приложения (роутинг, локатор)
├── models/                 # Модели данных
│   ├── user_model.dart
│   ├── airport_model.dart
│   ├── flight_model.dart
│   ├── booking_model.dart
│   ├── ticket_model.dart
│   └── payment_model.dart
├── services/               # Бизнес-логика и API
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── flight_service.dart
│   ├── booking_service.dart
│   └── payment_service.dart
└── ui/
    └── views/              # UI экраны
        ├── startup/
        ├── login/
        ├── register/
        ├── flight_search/
        ├── booking/
        ├── payment/
        ├── my_bookings/
        ├── booking_details/
        └── profile/
```

## API Интеграция

Приложение интегрировано с FastAPI бэкендом на `http://localhost:8000/api/v1`.

### Основные endpoints:

- `POST /login/access-token` - авторизация
- `POST /users/signup` - регистрация
- `GET /users/me` - текущий пользователь
- `GET /airports/` - список аэропортов
- `GET /flights/search` - поиск рейсов
- `POST /bookings` - создание бронирования
- `GET /bookings/me` - мои бронирования
- `POST /payments` - создание платежа

## Настройка бэкенда

Убедитесь, что бэкенд запущен на `localhost:8000`. Если бэкенд работает на другом адресе, измените `baseUrl` в `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://your-backend-url:port/api/v1';
```

## Особенности

- Автоматическое сохранение токенов авторизации
- Реактивное обновление UI при изменении состояния
- Обработка ошибок с понятными сообщениями
- Валидация данных перед отправкой
- Поддержка idempotency для платежей

## Документация

Подробное описание компонентов см. в [COMPONENTS.md](COMPONENTS.md)

## Лицензия

MIT
