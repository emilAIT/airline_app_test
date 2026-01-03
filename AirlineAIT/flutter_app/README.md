# Airline Booking Mobile App

Flutter mobile application for the Airline Booking System.

## Technology Stack

- **Framework**: Flutter (SDK ≥3.0.0)
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK for building APK

## Setup Instructions

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For Android emulator:
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For iOS simulator:
static const String baseUrl = 'http://localhost:8000/api';

// For physical device (replace with your computer's IP):
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

### 3. Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### 4. Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Features

### Passenger Features
- ✅ User registration and login
- ✅ Profile management (required before booking)
- ✅ Flight search (origin, destination, date)
- ✅ Visual seat map with categories
- ✅ Multi-passenger booking
- ✅ Mock payment (Card, Apple Pay, Google Pay)
- ✅ Check-in (24h to 1h before departure)
- ✅ Boarding pass with QR code
- ✅ Flight announcements
- ✅ My Trips view

### Staff/Admin Features
- ✅ Flight management (CRUD)
- ✅ Airplane management
- ✅ Booking management
- ✅ Announcement publishing
- ✅ Seat reassignment
- ✅ User management

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/
│   │   ├── admin/             # Admin dashboard
│   │   ├── auth/              # Login/Register
│   │   ├── bookings/          # Booking screens
│   │   ├── checkin/           # Check-in screens
│   │   ├── flights/           # Flight search/details
│   │   ├── home/              # Home screen
│   │   ├── payment/           # Payment screen
│   │   └── profile/           # Profile screens
│   ├── services/
│   │   ├── api_service.dart   # API client
│   │   └── auth_service.dart  # Auth state
│   ├── theme/                 # App theme
│   ├── utils/                 # Utilities
│   └── widgets/               # Reusable widgets
├── android/                   # Android config
├── pubspec.yaml              # Dependencies
└── test/                     # Tests
```

## UI States

The app properly handles:
- ✅ **Loading states** - `LoadingWidget`
- ✅ **Error states** - `ErrorDisplayWidget` with retry
- ✅ **Empty states** - `EmptyStateWidget`

## Platform Support

- ✅ **Android** - Fully supported
- ⚠️ **iOS** - Requires additional configuration
