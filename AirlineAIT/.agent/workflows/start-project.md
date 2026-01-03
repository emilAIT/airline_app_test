---
description: How to start the AirlineAIT project
---

Follow these steps to start the development servers for the AirlineAIT project.

### 1. Start the Backend
1. Open a terminal in the `backend` directory.
2. Activate the virtual environment:
   ```powershell
   .\venv\Scripts\activate
   ```
3. Start the FastAPI server:
   ```powershell
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

### 2. Start the Frontend (Flutter)
1. Open a terminal in the `flutter_app` directory.
2. Run the app in Chrome:
   ```powershell
   flutter run -d chrome
   ```

### 3. Access the Application
- Once the Flutter app starts, it will open a Chrome window.
- Login with the following credentials:
  - **Admin**: `admin@airline.com`
  - **Staff**: `staff@gmail.com`
  - **Password**: (The one you set during registration, typically `password123` for test accounts)
