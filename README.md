# Airline App 2026 Test for AIT Solutions

Видеообзор в ютубе https://youtu.be/U6Voixfr3VI?si=gd2l9tDWSwKN_sfh

Система бронирования авиабилетов с мобильным приложением на Flutter и backend API на FastAPI.

## 🔧 Требования

**Backend:**
- Python 3.10+ ([Скачать](https://www.python.org/downloads/))
- uv (рекомендуется) или pip ([Установка uv](https://github.com/astral-sh/uv#installation))
- Docker

**Flutter:**
- Flutter SDK 3.0.3+ ([Установка](https://docs.flutter.dev/get-started/install))
- Android Studio / VS Code с Flutter расширениями
- Android Emulator или физическое устройство

**Проверка:**
```bash
python --version    # 3.10+
flutter --version   # 3.0.3+
```

---

## 🚀 Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/emilAIT/airline_app_test.git
cd airline_app_test

# 2. Запустить Backend (см. раздел ниже)
# 3. Запустить Flutter приложение (см. раздел ниже)
```

---

## 🔙 Запуск Backend

```bash
cd backend
```

### Docker

```bash
docker-compose up --build backend
```

Откройте в браузере:
- **Swagger UI:** http://localhost:8000/docs
- **API:** http://localhost:8000

Если видите Swagger UI - backend запущен успешно! ✅

---

## 📱 Запуск Flutter приложения

### 1. Установите зависимости:

```bash
cd app
flutter pub get
```

### 2. Сгенерируйте код:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Настройте URL backend:

Откройте `lib/services/api_service.dart` и установите правильный URL:

**Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

**Физическое устройство:**
```dart
static const String baseUrl = 'http://YOUR_IP:8000/api/v1';
```

Узнать IP компьютера:
```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig
```

**Web:**
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

### 4. Запустите приложение:

```bash
flutter run -d chrome
```

Или через IDE (Android Studio / VS Code) - выберите устройство и нажмите Run.

---

## 👤 Тестовые данные

При первом запуске backend автоматически создает тестовые данные.

**Администратор (Staff):**
- Email: `admin@ex.kg`
- Password: `adminadmin`

**Тестовый пассажир:**
- Email: `passenger@ex.kg`
- Password: `passengerpass`

**Автоматически создаются:** аэропорты, самолеты, рейсы, бронирования, билеты, платежи.

---

## ⚠️ Типичные проблемы

### Backend не запускается

1. **Проверьте Python:** `python --version` (должно быть 3.10+)
2. **Проверьте `.env` файл:** должен быть в `backend/.env`, все переменные заполнены
3. **Переустановите зависимости:** `cd backend/backend && uv sync`
4. **Проверьте порт 8000:** `lsof -i :8000` (macOS/Linux)

### Flutter не подключается к API

1. **Проверьте backend:** откройте http://localhost:8000/docs - должна открыться документация
2. **Проверьте URL в `api_service.dart`:**
   - Emulator: `http://10.0.2.2:8000/api/v1`
   - Физическое устройство: IP компьютера + `:8000/api/v1`
3. **Устройство и компьютер в одной Wi-Fi сети** (для физического устройства)
4. **Проверьте файрвол** - порт 8000 должен быть открыт

### Ошибки при генерации кода Flutter

```bash
cd app
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### База данных не создается

```bash
# Создайте директорию
mkdir -p backend/data

# Пересоздайте БД
rm backend/data/app.db
# Запустите backend снова
```

### Проблемы с авторизацией

1. Выйдите и войдите снова
2. Очистите данные приложения на устройстве
3. Проверьте логи backend

---

## 📚 Полезные ссылки

- **API Документация:** http://localhost:8000/docs
- **Backend код:** `backend/backend/app/`
- **Flutter код:** `app/lib/`

---

**Удачной разработки! 🚀**
