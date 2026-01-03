# Airline App - Описание компонентов

## Обзор приложения

Flutter приложение для авиакомпании, интегрированное с FastAPI бэкендом на `localhost:8000`. Приложение позволяет пользователям искать рейсы, создавать бронирования, оплачивать билеты и управлять своими бронированиями.

## Архитектура

Приложение использует архитектуру **Stacked** (MVVM) с разделением на:
- **Models** - модели данных
- **Services** - бизнес-логика и API взаимодействие
- **ViewModels** - состояние и логика представлений
- **Views** - UI компоненты

## Структура компонентов

### 1. Модели данных (`lib/models/`)

#### `user_model.dart`
- `UserPublic` - публичная информация о пользователе
- `Token` - токен авторизации
- `UserRegister` - данные для регистрации
- `PassengerProfilePublic` - профиль пассажира
- `UserRole` - роли пользователя (PASSENGER, STAFF)

#### `airport_model.dart`
- `AirportPublic` - информация об аэропорте (код, название, город, страна)
- `AirportsPublic` - список аэропортов с количеством

#### `flight_model.dart`
- `FlightPublic` - информация о рейсе
- `FlightSearchResult` - результат поиска рейсов
- `FlightsPublic` - список рейсов
- `FlightStatus` - статусы рейса (SCHEDULED, BOARDING, DELAYED, CANCELLED, DEPARTED, LANDED)

#### `booking_model.dart`
- `BookingPublic` - информация о бронировании
- `BookingCreate` - данные для создания бронирования
- `BookingPassenger` - информация о пассажире в бронировании
- `BookingsPublic` - список бронирований
- `BookingStatus` - статусы бронирования (CREATED, CONFIRMED, CANCELLED)

#### `ticket_model.dart`
- `TicketPublic` - информация о билете

#### `payment_model.dart`
- `PaymentPublic` - информация о платеже
- `PaymentCreate` - данные для создания платежа
- `PaymentsPublic` - список платежей
- `PaymentMethod` - методы оплаты (CARD, APPLE_PAY, GOOGLE_PAY)
- `PaymentStatus` - статусы платежа (PENDING, PAID, FAILED)

### 2. Сервисы (`lib/services/`)

#### `api_service.dart`
Базовый сервис для HTTP запросов:
- Управление токенами авторизации (сохранение/получение)
- Методы: `get`, `post`, `patch`, `put`, `delete`
- Автоматическое добавление заголовков авторизации
- Поддержка form-urlencoded для login

#### `auth_service.dart`
Сервис авторизации:
- `login(username, password)` - вход в систему
- `register(userRegister)` - регистрация нового пользователя
- `getCurrentUser()` - получение текущего пользователя
- `logout()` - выход из системы
- Реактивное состояние авторизации

#### `flight_service.dart`
Сервис для работы с рейсами:
- `getAirports()` - получение списка аэропортов
- `searchFlights()` - поиск рейсов по параметрам
- `getFlight(flightId)` - получение информации о рейсе
- `getFlights()` - получение списка рейсов

#### `booking_service.dart`
Сервис для работы с бронированиями:
- `createBooking(booking)` - создание бронирования
- `getMyBookings()` - получение бронирований текущего пользователя
- `getBooking(bookingId)` - получение информации о бронировании
- `cancelBooking(bookingId)` - отмена бронирования

#### `payment_service.dart`
Сервис для работы с платежами:
- `createPayment()` - создание платежа (с idempotency key)
- `getMyPayments()` - получение платежей текущего пользователя
- `getPayment(paymentId)` - получение информации о платеже

### 3. UI Компоненты (`lib/ui/views/`)

#### `startup/startup_view.dart`
Экран загрузки приложения:
- Проверка авторизации пользователя
- Навигация на Login или FlightSearch в зависимости от статуса

#### `login/login_view.dart`
Экран входа:
- Поля для email и password
- Кнопка входа
- Навигация на регистрацию

#### `register/register_view.dart`
Экран регистрации:
- Поля: email, password, full name, phone, passport, nationality, date of birth
- Валидация полей
- Создание нового пользователя с профилем пассажира

#### `flight_search/flight_search_view.dart`
Главный экран поиска рейсов:
- Выбор аэропорта отправления
- Выбор аэропорта назначения
- Выбор даты вылета
- Поиск рейсов
- Отображение результатов поиска
- Навигация в профиль, бронирования, выход

#### `booking/booking_view.dart`
Экран создания бронирования:
- Отображение информации о рейсе
- Добавление пассажиров
- Создание бронирования
- Переход к оплате

#### `payment/payment_view.dart`
Экран оплаты:
- Выбор метода оплаты (Card, Apple Pay, Google Pay)
- Обработка платежа
- Переход к списку бронирований после успешной оплаты

#### `my_bookings/my_bookings_view.dart`
Экран моих бронирований:
- Список всех бронирований пользователя
- Просмотр деталей бронирования
- Отмена бронирования
- Pull-to-refresh

#### `booking_details/booking_details_view.dart`
Экран деталей бронирования:
- Информация о бронировании (PNR, статус)
- Список билетов в бронировании

#### `profile/profile_view.dart`
Экран профиля:
- Информация о пользователе
- Профиль пассажира

## Навигация

Приложение использует Stacked Router для навигации:
- `StartupView` - начальный экран
- `LoginView` - вход
- `RegisterView` - регистрация
- `FlightSearchView` - поиск рейсов (главный экран после входа)
- `BookingView` - создание бронирования
- `PaymentView` - оплата
- `MyBookingsView` - мои бронирования
- `BookingDetailsView` - детали бронирования
- `ProfileView` - профиль

## Конфигурация

### Базовый URL API
Настроен в `api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

### Зависимости
- `stacked` - архитектура MVVM
- `http` - HTTP клиент
- `json_annotation` / `json_serializable` - сериализация JSON
- `shared_preferences` - локальное хранилище токенов
- `intl` - форматирование дат
- `uuid` - генерация idempotency keys

## Запуск приложения

1. Установите зависимости:
```bash
flutter pub get
```

2. Сгенерируйте файлы:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Запустите приложение:
```bash
flutter run
```

## API Endpoints

Приложение использует следующие основные endpoints:

- `POST /api/v1/login/access-token` - вход
- `POST /api/v1/users/signup` - регистрация
- `GET /api/v1/users/me` - текущий пользователь
- `GET /api/v1/airports/` - список аэропортов
- `GET /api/v1/flights/search` - поиск рейсов
- `GET /api/v1/flights/{flight_id}` - информация о рейсе
- `POST /api/v1/bookings` - создание бронирования
- `GET /api/v1/bookings/me` - мои бронирования
- `POST /api/v1/payments` - создание платежа
- `GET /api/v1/tickets/booking/{booking_id}` - билеты по бронированию

## Особенности реализации

1. **Авторизация**: Токены сохраняются в SharedPreferences и автоматически добавляются к запросам
2. **Idempotency**: Платежи используют UUID для idempotency keys
3. **Реактивность**: AuthService использует ReactiveService для обновления UI при изменении статуса авторизации
4. **Обработка ошибок**: Все сервисы обрабатывают ошибки и выбрасывают исключения с понятными сообщениями
5. **Валидация**: ViewModels проверяют данные перед отправкой на сервер

