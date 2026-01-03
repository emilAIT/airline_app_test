# Zhan Airline ✈️

Система бронирования авиабилетов с Backend (FastAPI) и Frontend (Flutter Mobile/Web).

---

## 🎥 Демонстрация

*   **[Рекомендуется] Web версия (Chrome):** [Смотреть видео](https://youtu.be/PluMuRFCd1I?si=b-KuLerxT_gCqgf5)
*   **Мобильная версия:** [Смотреть Shorts](https://youtube.com/shorts/9SMglGWC1Xk?feature=share)

---

## ⚡ Быстрый запуск (Windows)

В корне проекта есть готовые скрипты для запуска:

1.  **Запуск Backend**: дважды кликните `start_backend.bat`
    *   Автоматически создаст виртуальное окружение, установит зависимости и инициализирует БД.
2.  **Запуск Frontend**: дважды кликните `start_frontend.bat`
    *   Автоматически запустит приложение (по умолчанию может открыться в браузере или на подключенном устройстве).

---

## 📋 Требования

Перед началом убедитесь, что у вас установлены:

| Компонент | Минимальная версия | Проверка |
|-----------|-------------------|----------|
| Python | 3.10+ | `python --version` |
| Flutter | 3.24+ | `flutter --version` |
| Git | любая | `git --version` |


---

## 🚀 Полная инструкция запуска с нуля

### Шаг 1: Клонирование проекта

```powershell
git clone <url-репозитория>
cd airline
```

---

### Шаг 2: Настройка Backend

#### 2.1 Создание виртуального окружения (рекомендуется)

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
```

#### 2.2 Установка зависимостей Python

```powershell
pip install -r requirements.txt
```

#### 2.3 Инициализация базы данных

```powershell
python init_db.py
```

Это создаст:
- Таблицы в базе данных (`airline.db`)
- Тестовые аккаунты
- Примеры аэропортов, самолётов и рейсов

#### 2.4 Запуск сервера Backend

```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

✅ **Проверка**: Откройте http://localhost:8000/docs — должен появиться Swagger UI.

---

### Шаг 3: Настройка Frontend

Откройте **новый терминал** (Backend должен продолжать работать).

#### 3.1 Переход в папку Flutter

```powershell
cd flutter_app
```

#### 3.2 Установка зависимостей Flutter

```powershell
flutter pub get
```

#### 3.3 Запуск приложения

```powershell
flutter run
```

*   **Android/iOS**: Если подключен телефон или эмулятор, приложение запустится на нём.
*   **Web**: Если устройств нет, появится меню выбора браузера (Chrome/Edge).

✅ **Готово!** Приложение откроется.

---

## 🔑 Тестовые аккаунты

| Роль | Email | Пароль |
|------|-------|--------|
| Пассажир | `passenger@test.com` | `pass123` |
| Персонал | `staff@airline.com` | `staff123` |

---

## 📁 Структура проекта

```
airline/
├── backend/                 # Backend (FastAPI + Python)
│   ├── app/                 # Код приложения
│   │   ├── core/            # Конфигурация, БД, безопасность
│   │   ├── models/          # SQLAlchemy модели
│   │   ├── schemas/         # Pydantic схемы
│   │   ├── services/        # Бизнес-логика
│   │   └── routes/          # API маршруты
│   ├── main.py              # Точка входа
│   ├── init_db.py           # Инициализация БД
│   └── requirements.txt     # Python зависимости
│
├── flutter_app/             # Frontend (Flutter Mobile/Web)
│   ├── android/             # Android native configuration
│   ├── ios/                 # iOS native configuration
│   ├── lib/                 # Исходный код
│   ├── web/                 # Web-специфичные файлы
│   └── pubspec.yaml         # Flutter зависимости
│
└── README.md                # Этот файл
```

---

## 🔧 Решение проблем

### Backend не запускается

1. **Python не найден**: Добавьте Python в PATH
2. **Модуль не найден**: Запустите `pip install -r requirements.txt`
3. **Порт занят**: Измените порт `--port 8001`

### Frontend не запускается

1. **Flutter не найден**: Установите Flutter SDK и добавьте в PATH
2. **Зависимости не установлены**: Запустите `flutter pub get`
3. **Нет соединения с API**: Убедитесь, что Backend запущен на порту 8000

### Ошибка "No devices found"

Выполните команду:
```powershell
flutter config --enable-web
```

---

## 📚 API Документация

После запуска Backend:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 📝 Лицензия

MIT
