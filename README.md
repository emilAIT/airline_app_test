# Aero Premier - Airline Mobile Application

A production-grade mobile flight booking application built with Flutter, designed to deliver a premium user experience comparable to leading international carriers. The project features a complete passenger flow from authentication to digital boarding pass generation, backed by a FastAPI microservice architecture.

## Overview

Aero Premier demonstrates a modern, scalable approach to airline app development. It prioritizes clean architecture, polished UI/UX, and robust engineering practices. The application adheres to Material 3 design principles while maintaining a distinct, luxury brand identity.

## key Features

### Mobile App (Flutter)
- **Fluid Navigation**: Seamless transition between screens using standard Flutter navigation patterns.
- **Premium Design System**: Custom theming with a refined color palette, Manrope typography, and consistent component hierarchy.
- **Detailed Flight Search**: Advanced search capability with date selection, passenger counts, and class filters.
- **Rich Results & Details**: Comprehensive flight cards and detailed itinerary views including amenity info.
- **Passenger Management**: Secure handling of passenger data and passport information.
- **Digital Boarding Pass**: Generation of QR-enabled boarding passes compatible with mobile wallets.

### Backend API (FastAPI)
- **Secure Authentication**: JWT-based auth flow (Login/Register) ensuring secure session management.
- **Flight Inventory**: Endpoints for searching flights based on origin, destination, and date.
- **Booking Engine**: Logic to create bookings, calculate pricing, and manage passenger manifests.
- **Payment Processing**: Mock payment gateway integration for simulating transactions.
- **SQLite Database**: Lightweight, zero-config persistence layer suitable for MVP and testing.

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Database**: SQLite / SQLAlchemy
- **Authentication**: OAuth2 / JWT
- **Design**: Material 3 / Google Fonts

## Project Structure

```
emil-airlines/
├── lib/                        # Flutter App Source
│   ├── main.dart               # Entry point
│   ├── booking_summary_screen.dart
│   ├── login_screen.dart
│   ├── flight_search_screen.dart
│   └── ... (screen widget)
├── backend/                    # FastAPI Backend Source
│   ├── main.py                 # API Routes
│   ├── models.py               # ORM Models
│   ├── schemas.py              # Pydantic Schemas
│   ├── security.py             # Auth Utilities
│   └── database.py             # DB Session 
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Python (3.9+)

### Running the Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies (recommended to use venv):
   ```bash
   pip install fastapi uvicorn sqlalchemy pydantic passlib python-jose[cryptography]
   ```
3. Start the server:
   ```bash
   uvicorn main:app --reload
   ```
   The API will be available at `http://127.0.0.1:8000`.

### Running the Mobile App

1. Navigate to the root directory:
   ```bash
   flutter pub get
   ```
2. Run on your preferred emulator or device:
   ```bash
   flutter run
   ```

## Future Roadmap

- [ ] **Seat Map Visualization**: Interactive seat selection with vector graphics.
- [ ] **Real-world Payment Integration**: Stripe or PayPal implementation.
- [ ] **Push Notifications**: Real-time updates for flight status changes.
- [ ] **Check-in Flow**: Automated check-in process 24h prior to departure.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
