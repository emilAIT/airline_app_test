# ELDIK AirLines - Airline Booking System

A full-stack airline booking and operations management system built with FastAPI (backend) and Flutter (mobile app). This system provides comprehensive flight booking, seat selection, payment processing, check-in, and boarding pass management capabilities.

## Project Overview

**ELDIK AirLines** is a modern airline booking system designed for both passengers and airline staff. The system enables passengers to search for flights, select seats with temporary holds, make bookings, process payments, check in, and receive digital boarding passes. Staff members can manage flights, bookings, announcements, and monitor operations through a dedicated interface.

## Tech Stack

### Backend
- **Python** 3.10+
- **FastAPI** - Modern, fast web framework for building APIs
- **JWT** (JSON Web Tokens) - Authentication and authorization
- **SQLite** - Lightweight database (ideal for development and exams)
- **SQLAlchemy** - ORM for database operations
- **Uvicorn** - ASGI server

### Frontend (Mobile)
- **Flutter** 3.10.4+ - Cross-platform mobile framework
- **Dart** SDK ^3.10.4

## Backend Setup

### Prerequisites
- Python 3.10 or higher
- pip (Python package manager)

### Step-by-Step Installation

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate a virtual environment (recommended):**
   ```bash
   # Create virtual environment
   python -m venv venv

   # Activate virtual environment
   # On macOS/Linux:
   source venv/bin/activate
   # On Windows:
   venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   cd app
   pip install -r requirements.txt
   ```

4. **Database Setup:**
   The database tables are created automatically when the server starts. The system uses SQLite, and the database file (`airline.db`) will be created in the `backend` directory.

5. **Seed the Database (Required):**
   Open a new terminal and run the seed script to populate the database with test data:
   ```bash
   cd backend
   python seed_realistic_announcements.py
   ```
   
   This creates:
   - Sample airports (FRU, IST, DXB, LHR, ALA)
   - Sample airplanes and flights
   - Test user accounts (see Test Credentials below)
   - Sample announcements and photos

6. **Start the FastAPI Server:**
   From the `backend` directory, run:
   ```bash
   uvicorn app.main:app --reload
   ```
   
   Or alternatively, run:
   ```bash
   python main.py
   ```

7. **Verify the Backend is Running:**
   - Server should start on: `http://0.0.0.0:8000`
   - API Documentation (Swagger): `http://127.0.0.1:8000/docs`
   - ReDoc Documentation: `http://127.0.0.1:8000/redoc`

   You should see output like:
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000
   INFO:     Application startup complete.
   ```

## Flutter Setup

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Android Studio / Xcode (for mobile development)
- An Android emulator, iOS simulator, or physical device

### Step-by-Step Installation

1. **Navigate to the Flutter app directory:**
   ```bash
   cd flutter
   ```

2. **Configure the API Base URL:**
   
   Open `lib/services/api_service.dart` and update the `baseUrl` constant (line 9) based on your target platform:
   
   **For Android Emulator:**
   ```dart
   static const String baseUrl = "http://10.0.2.2:8000";
   ```
   
   **For iOS Simulator:**
   ```dart
   static const String baseUrl = "http://127.0.0.1:8000";
   ```
   
   **For Physical Device:**
   1. Find your computer's IP address:
      - **macOS/Linux**: Run `ifconfig` or `ip addr` and look for your network interface's IPv4 address (e.g., `192.168.1.100`)
      - **Windows**: Run `ipconfig` and look for IPv4 Address
   
   2. Update the URL:
   ```dart
   static const String baseUrl = "http://192.168.1.100:8000";
   ```
   
   **⚠️ Important:** Ensure your physical device and computer are on the **same Wi-Fi network**.

3. **Clean and Install Dependencies:**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **Check Available Devices:**
   ```bash
   flutter devices
   ```

5. **Run the App:**
   ```bash
   # Run on first available device
   flutter run

   # Or specify a device
   flutter run -d <device-id>
   
   # Run on Android emulator
   flutter run -d android
   
   # Run on iOS simulator
   flutter run -d ios
   ```

## Test Credentials

The following test accounts are created by the seed script:

### Staff/Admin Account
- **Email:** `admin@eldiyar.com`
- **Password:** `password123`
- **Role:** Staff (full admin access)

### Passenger Account
- **Email:** `test@eldiyar.com`
- **Password:** `password123`
- **Role:** Passenger

## Key Features

### Passenger Features
- ✈️ **Flight Search** - Search flights by origin, destination, and date
- 🪑 **Seat Selection** - Interactive seat map with 10-minute temporary holds
- 💳 **Mock Payment Processing** - Process payments with card or Apple Pay (Stripe integration)
- 🎫 **Booking Management** - View and manage flight bookings
- ✅ **Online Check-in** - Check in for flights and receive boarding passes
- 📱 **Digital Boarding Pass** - QR code boarding pass for easy access
- 🔔 **Real-time Notifications** - Receive flight updates and announcements

### Staff Features
- 🛫 **Flight Management** - Create and update flights
- 📋 **Booking Oversight** - View and manage all passenger bookings
- 🪑 **Seat Reassignment** - Reassign passenger seats when needed
- 📢 **Announcement System** - Create flight-specific or global announcements
- 🏢 **Airport & Aircraft Management** - Manage airports and airplane fleet
- 📸 **Photo Management** - Upload and manage photos for airports and destinations

### System Features
- 🔐 **JWT Authentication** - Secure token-based authentication
- ⏱️ **Automatic Expiration** - Seats and bookings automatically expire after hold period
- 📊 **Real-time Updates** - Live flight status and gate information
- 🎨 **Modern UI** - Beautiful, responsive Flutter interface with animations

## Database Information

This project uses **SQLite** for simplicity and ease of setup, making it ideal for development and exam scenarios. The database file (`airline.db`) is automatically created in the `backend` directory when the server starts.

- **Database Location:** `backend/airline.db`
- **Tables Created Automatically:** All tables are created on server startup via SQLAlchemy
- **No Manual Migrations Required:** Database schema is managed through SQLAlchemy models

## API Documentation

Once the backend server is running, you can access:
- **Swagger UI:** `http://127.0.0.1:8000/docs` - Interactive API documentation
- **ReDoc:** `http://127.0.0.1:8000/redoc` - Alternative API documentation format

## Project Structure

```
airline/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI application entry point
│   │   ├── database.py          # Database configuration
│   │   ├── requirements.txt     # Python dependencies
│   │   ├── routers/             # API route handlers
│   │   ├── models/              # SQLAlchemy database models
│   │   ├── schemas/             # Pydantic schemas
│   │   └── services/            # Business logic
│   ├── seed_realistic_announcements.py  # Database seeding script
│   └── main.py                  # Alternative server entry point
├── flutter/
│   ├── lib/
│   │   ├── main.dart            # Flutter app entry point
│   │   ├── services/            # API service and utilities
│   │   ├── screens/             # UI screens
│   │   ├── widgets/             # Reusable widgets
│   │   └── models/              # Data models
│   └── pubspec.yaml             # Flutter dependencies
└── README.md                    # This file
```

## Troubleshooting

### Backend Issues

**Port already in use:**
- Change the port in `backend/main.py` or use: `uvicorn app.main:app --reload --port 8001`

**Database errors:**
- Delete `backend/airline.db` and restart the server (tables will be recreated)
- Re-run the seed script: `python seed_realistic_announcements.py`

**Import errors:**
- Ensure you're in the correct directory
- Activate your virtual environment
- Reinstall dependencies: `pip install -r app/requirements.txt`

### Flutter Issues

**Connection refused:**
- Verify backend is running: `curl http://127.0.0.1:8000/`
- Check the `baseUrl` in `api_service.dart` matches your platform
- For physical devices, ensure same Wi-Fi network

**Build errors:**
- Run `flutter clean && flutter pub get`
- Check Flutter version: `flutter --version` (should be 3.10.4+)
- Run `flutter doctor` to diagnose issues

**No devices found:**
- Start an emulator/simulator from Android Studio or Xcode
- Check with: `flutter devices`

## Quick Start Commands

```bash
# Terminal 1: Start Backend
cd backend
source venv/bin/activate  or venv\Scripts\activate on Windows
uvicorn app.main:app --reload --port 8000

# Terminal 2: Seed Database (one-time)
cd backend
python3 seed_realistic_announcements.py

# Terminal 3: Run Flutter App
cd flutter
flutter clean
flutter pub get
flutter run
```

## License

This project is created for educational/examination purposes.

---

**Built with ❤️ for ELDIK AirLines**

i hope you liked it whoever you are




## 🛠 Troubleshooting (Common Issues)

### 1. ModuleNotFoundError (email_validator, stripe, etc.)
If you see errors like `ModuleNotFoundError: No module named 'email_validator'` or `stripe`, even after running `pip install`, it means your system has multiple Python versions (especially on macOS).

**The Fix:**
Run the installation specifically for the Python version you are using to start the server (e.g., 3.13):
```bash
python3.13 -m pip install "pydantic[email]" email-validator stripe

Or install all requirements at once:

python3.13 -m pip install -r app/requirements.txt

Port 8000 is already in use

If Uvicorn fails to start because the port is taken:

# Find the process and kill it (macOS/Linux)
lsof -ti:8000 | xargs kill -9

# Or run on a different port
uvicorn app.main:app --reload --port 8001

Database is "Locked" or Out of Sync

If you've made many changes and the database is behaving weirdly:

Delete backend/airline.db.

Restart the server (tables will be recreated).

Run the seed script: python3.13 seed_realistic_announcements.py.


