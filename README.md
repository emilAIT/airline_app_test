Aero Premier – Airline Mobile Application

A Flutter-based airline booking mobile application developed as part of the AIT Solutions technical test.
The project demonstrates a complete booking flow supported by a FastAPI backend.

Overview

Aero Premier provides a clean and structured airline booking experience, including:

Flight search

Passenger information

Booking summary

Boarding pass flow

Key Features
Mobile App (Flutter)

Flight search and results

Flight details and booking summary

Passenger information input

Seat selection

Mock payment flow

Boarding pass screen

Backend API (FastAPI)

JWT-based authentication

Flight inventory endpoints

Booking logic

SQLite database

Technology Stack

Frontend: Flutter (Dart)

Backend: FastAPI (Python)

Database: SQLite / SQLAlchemy

Authentication: JWT

Project Structure

airline_app_test/
├── app/
│ ├── lib/
│ │ ├── main.dart
│ │ └── ...
│ ├── pubspec.yaml
│ └── pubspec.lock
│
├── backend/
│ ├── main.py
│ ├── models.py
│ ├── schemas.py
│ ├── security.py
│ └── database.py
│
└── README.md

How to Run the Project
Prerequisites

Flutter SDK (3.0 or higher)

Python 3.9 or higher

Run Backend

Open terminal in project root:

cd backend
pip install fastapi uvicorn sqlalchemy pydantic passlib python-jose[cryptography]
uvicorn main:app --reload

Backend will run at:
http://127.0.0.1:8000

Run Flutter App

Open terminal in project root:

cd app
flutter pub get
flutter run

Demo Video

https://youtu.be/ziyMW9R6ZRo

Notes

Flutter frontend is located in the app/ folder

Backend API is located in the backend/ folder

Project is submitted using a dedicated submission branch

License

This project is provided for technical evaluation purposes only.