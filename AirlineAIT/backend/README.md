# Airline Booking & Operations API

FastAPI backend for the Airline Booking System.

## Technology Stack

- **Framework**: FastAPI 0.104.1
- **Database**: SQLite (`airline.db`)
- **Authentication**: JWT (python-jose)
- **Python**: 3.10+

## Setup Instructions

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Seed the Database

```bash
python seed_data.py
```

This creates:
- 8 airports (IST, JFK, LHR, CDG, DXB, FRA, AMS, MAD)
- 3 seat templates (Boeing 737, Airbus A320, Boeing 777)
- 4 airplanes
- 180 sample flights (30 days)
- Admin user

### 4. Run the Server

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## API Base URL

```
http://localhost:8000/api
```

For Android emulator, use: `http://10.0.2.2:8000/api`

## Admin Credentials

| Field | Value |
|-------|-------|
| Email | `admin@airline.com` |
| Password | `admin123` |
| Role | ADMIN |

## API Endpoints Overview

| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/register` | Register new user |
| `POST /api/auth/login` | Login and get JWT token |
| `GET /api/auth/me` | Get current user info |
| `GET /api/flights/airports` | List all airports |
| `GET /api/flights/search` | Search flights |
| `GET /api/flights/{id}` | Get flight details |
| `GET /api/flights/{id}/seat-map` | Get seat map |
| `POST /api/bookings` | Create booking |
| `GET /api/bookings` | List user's bookings |
| `POST /api/payments` | Process payment |
| `POST /api/checkin/ticket/{id}` | Check-in for ticket |
| `GET /api/checkin/ticket/{id}/boarding-pass` | Get boarding pass |
| `GET /api/announcements/my-flights` | Get announcements |
| `GET /api/staff/*` | Staff/Admin endpoints |

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── routes/      # API route handlers
│   │   ├── deps.py      # Dependencies (auth)
│   │   └── main.py      # Router aggregation
│   ├── core/
│   │   └── config.py    # App configuration
│   ├── db/
│   │   ├── base.py      # SQLAlchemy Base
│   │   └── session.py   # Database session
│   ├── models/          # SQLAlchemy models
│   ├── schemas/         # Pydantic schemas
│   ├── services/        # Business logic
│   └── utils/           # Utilities
├── seed_data.py         # Database seeding
├── requirements.txt     # Dependencies
└── airline.db           # SQLite database
```
