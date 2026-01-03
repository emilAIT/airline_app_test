# AITS Airline - Flutter Frontend

## How to Run

**Prerequisites:** Flutter SDK 3.0.0+, Android device/emulator, Backend running

**Steps:**
```bash
cd frontend
flutter pub get
flutter run
```

## Backend Configuration

Edit `lib/config.dart`:

```dart
// Android Emulator
return 'http://10.0.2.2:8000/api/v1';

// Physical Device (replace with your computer's IP)
return 'http://YOUR_COMPUTER_IP:8000/api/v1';
```

Find IP on Windows: Run `ipconfig`, look for IPv4 Address

## APK (Optional)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Test Credentials

**Passenger:** `john_doe` / `passenger123`  
**Staff:** `staff` / `staff123`

## Features
- Passenger: Search flights, book seats, mock payment, check-in, boarding pass with QR, view trips
- Staff: Manage flights/airplanes, create announcements, manage bookings

## Tech Stack
Flutter, flutter_bloc, http, shared_preferences, qr_flutter
