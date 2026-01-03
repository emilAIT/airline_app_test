# Airplane Booking & Operations System

A modern, full-stack airline management application built with **FastAPI** (Backend) and **Flutter** (Frontend).

## 🚀 Working Features

### 👤 Passenger Features
- **Secure Authentication**: User registration and login powered by OAuth2 and JWT tokens.
- **Flight Search**: Search for available flights by origin, destination, and date.
- **Interactive Seat Selection**: 
  - Real-time seat map visualization.
  - Temporary seat hold mechanism to prevent double booking.
- **Complete Booking Flow**:
  - Seamless seat selection and booking creation.
  - Integrated payment mockup with success redirection.
  - Automated post-payment navigation back to Home.
- **My Trips Dashboard**:
  - View full booking history with real-time data.
  - Details include PNR code, Route, and Booking Status.
- **Digital Boarding Pass**:
  - View specific seat assignments, flight numbers, and gate information.
  - Generated QR code for check-in verification.
- **Airport & Flight Discovery**: Browse comprehensive lists of all supported airports and available flights.
- **Announcements**: Stay informed with global and flight-specific real-time announcements.

### 🛠️ Staff & Management Features
- **Staff Dashboard**: Centralized hub for airline operations.
- **Flight Management**: Tools to manage and monitor scheduled flights.
- **Announcement Management**: Create and broadcast global or flight-specific updates to passengers.

### ⚙️ Backend & System Features
- **Scalable Architecture**: Built with FastAPI for high performance.
- **Robust Database**: SQLAlchemy integration with SQLite for reliable data persistence.
- **CORS Support**: Fully configured for secure web communication.
- **Global Error Handling**: Standardized API responses with comprehensive error reporting for a smooth frontend experience.
- **Clean API Design**: RESTful endpoints with consistent trailing-slash handling.

## 🛠️ Technology Stack
- **Frontend**: Flutter (Mobile & Web)
- **Backend**: FastAPI (Python 3.10+)
- **Database**: SQLAlchemy & SQLite
- **Authentication**: JWT & OAuth2
- **Styling**: Vanilla CSS (Web) & Material Design 3 (Flutter)

## 🚦 How to Run

### Backend
1. Navigate to `backend/`.
2. Install dependencies: `pip install -r requirements.txt`.
3. Run the server: `python main.py`.

### Frontend
1. Navigate to `frontend/`.
2. Get packages: `flutter pub get`.
3. Run the app: `flutter run -d chrome --web-port=8080` (or your preferred device).

### Video
link: https://drive.google.com/drive/folders/1jNLiExeyJ74gjnUcBsaodSDGE2o3iggm
