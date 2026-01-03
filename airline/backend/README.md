# Airline Booking & Operations System - Backend

FastAPI backend for the airline booking system.

## Setup Instructions

### Prerequisites
- Python 3.10 or higher
- pip (Python package manager)

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment (recommended):
```bash
python -m venv venv
```

3. Activate the virtual environment:
   - On macOS/Linux:
     ```bash
     source venv/bin/activate
     ```
   - On Windows:
     ```bash
     venv\Scripts\activate
     ```

4. Install dependencies:
```bash
pip install -r app/requirements.txt
```

### Database

The system uses SQLite by default. The database file (`airline.db`) will be created automatically when you run the application.

### Running the Application

1. Navigate to the `app` directory:
```bash
cd app
```

2. Run the FastAPI server:
```bash
uvicorn main:app --reload --port 8001
```

The API will be available at:
- API: http://127.0.0.1:8001
- Swagger Documentation: http://127.0.0.1:8001/docs
- ReDoc Documentation: http://127.0.0.1:8001/redoc

### Seeding the Database

To populate the database with sample data (airports, flights, users):

1. From the `backend` directory:
```bash
python seed.py
```

This will create:
- Sample airports (FRU, DXB, IST, JFK, LHR, CDG)
- Sample airplanes with seat configurations
- Sample flights
- Test users:
  - Staff: `admin@airline.com` / `admin123`
  - Passenger: `passenger@example.com` / `pass123`

### API Base URL

- Local: `http://127.0.0.1:8001`
- For Android Emulator: `http://10.0.2.2:8001`
- For iOS Simulator: `http://127.0.0.1:8001`
- For Physical Device: Use your computer's IP address (e.g., `http://192.168.1.100:8001`)

### Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── database.py          # Database configuration
│   ├── core/
│   │   └── config.py         # Application settings
│   ├── models/
│   │   └── all_models.py    # SQLAlchemy models
│   ├── schemas/
│   │   └── schemas.py       # Pydantic schemas
│   ├── routers/             # API route handlers
│   │   ├── auth.py          # Authentication endpoints
│   │   ├── flights.py       # Flight search and details
│   │   ├── bookings.py      # Booking management
│   │   ├── passenger.py     # Passenger profile
│   │   ├── payments.py      # Payment processing
│   │   ├── checkin.py       # Check-in and boarding passes
│   │   ├── announcements.py # Announcements
│   │   └── staff.py         # Staff/admin endpoints
│   ├── services/            # Business logic
│   │   ├── booking_service.py
│   │   ├── payment_service.py
│   │   ├── checkin_service.py
│   │   └── seat_service.py
│   └── auth/
│       └── auth_handler.py  # JWT authentication
├── seed.py                  # Database seeding script
└── requirements.txt         # Python dependencies
```

### Key Features

- **Authentication**: JWT-based authentication with role-based access control
- **Flight Management**: Search flights, view details, seat maps
- **Booking System**: Create bookings with seat selection and 10-minute hold
- **Payment**: Mock payment processing (CARD, APPLE_PAY, GOOGLE_PAY)
- **Check-in**: Check-in 24 hours to 1 hour before departure
- **Announcements**: Flight-related announcements
- **Staff Features**: Manage flights, bookings, and announcements

### Environment Variables

The application uses default settings. To customize, modify `app/core/config.py`:
- `SECRET_KEY`: JWT secret key
- `DATABASE_URL`: Database connection string
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration time

### Testing

You can test the API using:
1. Swagger UI at `/docs`
2. ReDoc at `/redoc`
3. Any HTTP client (Postman, curl, etc.)

### Notes

- The database file (`airline.db`) is created in the `backend` directory
- Seat holds expire after 10 minutes automatically (background task runs every minute)
- Mock payments always succeed
- All timestamps are in UTC

Payments are handled as non-recurring one-time payments using Stripe Payment Intents.
Subscriptions and marketplace features are not used.
