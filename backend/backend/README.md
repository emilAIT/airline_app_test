Backend (FastAPI)

Backend API for an airline booking system built with FastAPI + SQLModel.

Includes seeded demo data (admin and passenger) for quick frontend integration.

Tech Stack

Python 3.10+

FastAPI

SQLModel + SQLite

JWT authentication

Docker & Docker Compose

Quick Start (Docker)
1. Requirements

Docker

Docker Compose

2. Environment variables

Create .env in the project root:

PROJECT_NAME=Airlines
SQLITE_DB=sqlite:///./airline.db

# Admin (STAFF)
FIRST_SUPERUSER=admin@ex.kg
FIRST_SUPERUSER_PASSWORD=adminadmin

# Seed passenger (for frontend testing)
PASSENGER_EMAIL=passenger@ex.kg
PASSENGER_PASSWORD=passengerpass
PASSENGER_FULL_NAME=Seed Passenger
PASSENGER_PHONE=+996700000000
PASSENGER_PASSPORT=AN1234567
PASSENGER_NATIONALITY=Kyrgyzstan
PASSENGER_DOB=2000-01-01

3. Run backend
docker compose up --build backend


Backend will be available at:

API: http://localhost:8000

Swagger UI: http://localhost:8000/docs

OpenAPI JSON: http://localhost:8000/openapi.json

Seeded Data

On startup, the application automatically creates:

Users

Admin (STAFF) – from FIRST_SUPERUSER

Passenger (PASSENGER) – from PASSENGER_* env variables

Demo data

Airports

Airplanes and seat templates

Flights and seats

Passenger profile

Booking with seats

Tickets

Payment (PAID)

Check-in + boarding pass

Seat hold

Announcement

This allows frontend apps to immediately use all GET endpoints without manual setup.

Authentication

JWT Bearer authentication

Obtain token via:

POST /api/v1/login/access-token


Use the returned access_token as:

Authorization: Bearer <token>