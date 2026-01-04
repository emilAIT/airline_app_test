# ✈️ AIT Airlines

Система управления авиакомпанией с веб-приложением на Flutter и REST API на FastAPI.

## 📋 Описание

AIT Airlines - полнофункциональная система для управления авиарейсами, бронированиями и пассажирами. Проект включает:
- **Backend**: FastAPI (Python) с SQLModel ORM
- **Frontend**: Flutter (Dart) с поддержкой Web, Android, iOS
- **База данных**: SQLite (для разработки)

## 📹 Видео-туториал

Видео-инструкция по эксплуатации системы:
- [Туториал по эксплуатации](https://youtube.com/shorts/0VScZp5g3ek?si=ysm1FMzIstAHfaok)

## 🚀 Быстрый старт

### Предварительные требования

- **Python 3.8+**
- **Flutter SDK** (проверьте: `flutter --version`)
- **Android Studio** (для Android эмулятора) или браузер Chrome (для веб)

### Запуск Backend

1. Перейдите в папку `backend`:
   ```bash
   cd backend
   ```

2. Запустите сервер:
   ```bash
   start_backend.bat
   ```
   
   Или вручную:
   ```bash
   .\venv\Scripts\activate
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

3. Проверьте работу: откройте `http://localhost:8000/docs` в браузере

### Запуск Frontend

#### Вариант A: Браузер (Chrome)

```bash
cd mobile_app
flutter pub get
flutter run -d chrome
```

#### Вариант B: Android эмулятор

1. Запустите Android эмулятор в Android Studio
2. Проверьте устройства:
   ```bash
   cd mobile_app
   flutter devices
   ```
3. Запустите приложение:
   ```bash
   flutter run
   ```

#### Вариант C: Автоматический запуск

Дважды кликните на `run_android.bat` в корне проекта (запустит backend и приложение)

## 🔧 Конфигурация

### API Endpoints

Адрес API определяется автоматически:
- **Браузер**: `http://localhost:8000`
- **Android эмулятор**: `http://10.0.2.2:8000` (автоматически)
- **iOS симулятор**: `http://localhost:8000`

Для физического Android устройства измените адрес в `mobile_app/lib/core/network/api_client.dart` на IP вашего компьютера.

## 📁 Структура проекта

```
AIT SOLUTION/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/         # API endpoints
│   │   ├── models/      # Модели данных
│   │   ├── services/    # Бизнес-логика
│   │   └── main.py      # Точка входа
│   ├── venv/            # Виртуальное окружение
│   └── start_backend.bat
│
├── mobile_app/          # Flutter frontend
│   ├── lib/
│   │   ├── core/        # Ядро приложения
│   │   └── features/    # Функциональные модули
│   └── pubspec.yaml
│
└── README.md
```

## 🎯 Основные функции

### Для пассажиров:
- Поиск и бронирование рейсов
- Выбор мест
- Управление бронированиями
- Check-in (24 часа - 1 час до вылета)
- История бронирований
- Профиль пользователя

### Для сотрудников (Staff):
- Просмотр пассажиров по рейсам
- Пересадка пассажиров
- Изменение гейтов
- Изменение статуса рейсов
- Создание объявлений

### Для администраторов:
- Управление рейсами
- Управление самолетами
- Управление аэропортами
- Управление сотрудниками
- Управление пользователями

## 🛠️ Полезные команды

### Flutter:
- `flutter doctor` - проверка окружения
- `flutter devices` - список устройств
- `flutter clean` - очистка кэша
- `flutter pub get` - установка зависимостей
- `r` в консоли - hot reload
- `R` в консоли - hot restart

### Backend:
- `uvicorn app.main:app --reload` - запуск с автоперезагрузкой
- `http://localhost:8000/docs` - Swagger документация
- `http://localhost:8000/redoc` - ReDoc документация

## ⚠️ Решение проблем

**"No devices found"**
- Убедитесь, что эмулятор запущен
- Проверьте: `flutter doctor`

**"Connection refused"**
- Проверьте, что backend запущен на `0.0.0.0:8000`
- Проверьте: `http://localhost:8000/docs`

**"Gradle build failed"**
```bash
cd mobile_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 🔒 Безопасность

- JWT токены для аутентификации
- CORS настроен для разработки (обновите для production)
- Валидация данных на backend и frontend
- Хеширование паролей (bcrypt)

## 📝 Лицензия

Этот проект создан для образовательных целей.

## 👥 Авторы

AIT Solution Team

---

**Версия:** 2.0.0  
**Последнее обновление:** 2024


