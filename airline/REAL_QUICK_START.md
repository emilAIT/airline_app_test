### Staff/Admin Account
- **Email:** `admin@eldiyar.com`
- **Password:** `password123`
- **Role:** Staff (full admin access)

### Passenger Account
- **Email:** `test@eldiyar.com`
- **Password:** `password123`
- **Role:** Passenger

cd backend
source venv/bin/activate  or venv\Scripts\activate on Windows
uvicorn app.main:app --reload --port 8000

cd flutter
flutter clean
flutter pub get
flutter run

if something wrong change in flutter/lib/services/api_service.dart if android or something else 
 // For Android emulator use: http://10.0.2.2:8001
  // For iOS simulator use: http://127.0.0.1:8001
  // For physical device use your computer's IP address

https://youtu.be/UnrpH1EowoU?si=7cedIocFKcpK_8Od