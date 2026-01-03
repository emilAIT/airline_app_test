
#YOUTUBE PROJECT VIDEO LINK: "https://www.youtube.com/watch?v=X9Q7v2IGfV0"

# Airline Booking System (IBO Airlines)

A comprehensive airline booking system consisting of a FastAPI backend and a Flutter frontend.

## Prerequisites

- **Backend**: Python 3.10+, `pip`, `virtualenv`
- **Frontend**: Flutter SDK 3.0+, Android Studio / VS Code, Chrome (for web)

---

## Quick Start Guide

Follow these steps to get the application running locally.

### Step 1: Start the Backend Server

1.  Open a terminal.
2.  Navigate to the `backend` directory:
    ```bash
    cd backend
    ```
3.  Create and activate a virtual environment (if not already done):
    ```bash
    # Create venv (first time only)
    python -m venv venv
    
    # Activate (Windows)
    .\venv\Scripts\activate
    
    # Activate (Mac/Linux)
    source venv/bin/activate
    ```
4.  Install dependencies (first time only):
    ```bash
    pip install -r requirements.txt
    ```
5.  **Initialize & Populate Data (Required for fresh start):**
    Run these scripts in order to set up the database, accounts, and testing data:
    ```bash
    # 1. Core setup (Airports, Airplanes, Flights, Admin, Staff)
    python seed_data.py

    # 2. Extended data (More flights, passengers, and bookings)
    python populate_data.py

    # 3. Specific test cases (e.g., Landed flights)
    python seed_landed_flight.py
    ```
6.  **Start the server:**
    ```bash
    python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
    ```
    *The server will start at `http://localhost:8000`*

### Step 2: Start the Frontend Application

1.  Open a **new** terminal.
2.  Navigate to the `flutter_app` directory:
    ```bash
    cd flutter_app
    ```
3.  Install dependencies (first time only):
    ```bash
    flutter pub get
    ```
4.  Run the application in Chrome:
    ```bash
    flutter run -d chrome
    ```

---

## Default Login Credentials

Use these accounts to test different roles. 

### Core Accounts (Created by `seed_data.py`)
| Role | Email | Password | Status |
|------|-------|----------|--------|
| **Administrator** | `admin@airline.com` | `admin123` | Active |
| **Staff Member** | `staff@airline.com` | `staff123` | Active |
| **Pending Staff 1** | `pending_staff@airline.com` | `staff123` | **Pending Approval** |
| **Pending Staff 2** | `pending_staff2@airline.com` | `staff123` | **Pending Approval** |

### Standardized Test Data (Simplified)
To provide a clean testing environment, the database is seeded with:
- **4 Airports**: Istanbul (IST), New York (JFK), London (LHR), Dubai (DXB).
- **7 Total Flights**: 5 active/scheduled flights and 2 landed (past) flights.
- **Airplanes**: 4 airplanes (Boeing 737, Airbus A320, Boeing 777-300ER).

### Test Passengers (Created by `populate_data.py`)
All test passengers use the default password: **`password123`**

| Name | Email | Test Scenario |
|------|-------|---------------|
| Alice Walker | `alice@example.com` | ~3 Paid Bookings, 1 Pending (HOLD) |
| Bob Builder | `bob@example.com` | ~3 Paid Bookings, 1 Pending (HOLD), Past Trip(s) |

---
> [!TIP]
> **Registration Note**: You can also register new accounts via the mobile app. 
> - **Passengers** are active immediately.
> - **Staff** accounts are registered but require **Admin Approval** via the Admin Dashboard before they can log in.

---

## Operational Timing Rules

The system enforces several timing constraints during the booking and travel lifecycle:

| Action | Event | Rule |
|--------|-------|------|
| **Booking** | Search & Creation | Closes **1 hour** before departure |
| **Seat Hold** | Payment Reservation| Valid for **10 minutes** (expires if unpaid) |
| **Check-in** | Confirmation | Opens **24 hours** before, Closes **1 hour** before |
| **Cancellation**| User/API Action | Blocked once Check-in starts (**24 hours**) |
| **Boarding** | Pass Display | Starts **1 hour** before departure |
| **Past Trips** | My Trips UI | Classified if flight > Departure time or LANDED |

---

