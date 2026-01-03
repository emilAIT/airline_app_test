# Airline Booking & Operations System - Backend

## Database Choice
**SQLite** - File: `airline.db`

## Setup Steps
```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python seed_data.py
```

## How to Run
```powershell
python -m uvicorn app.main:app --reload

# For physical devices:
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Base URL
- Local: `http://localhost:8000/api/v1`
- Network: `http://<YOUR_IP>:8000/api/v1`
- Docs: `http://localhost:8000/docs`

## Admin Credentials

**Staff:**
- Username: `staff`
- Password: `staff123`

**Passengers:**
- Username: `john_doe`, Password: `passenger123`
- Username: `jane_smith`, Password: `passenger123`

## Tech Stack
Python 3.13, FastAPI, SQLite, SQLAlchemy, JWT

## Features
- Passenger: Flight search, booking, mock payment, check-in, boarding pass with QR, announcements
- Staff: Manage flights/airplanes, create announcements, manage bookings/seats
