# Airline Booking & Operations System - Flutter App

Flutter mobile application for the airline booking system.

## Setup Instructions

### Prerequisites
- Flutter SDK (3.10.4 or higher)
- Android Studio / Xcode (for Android/iOS development)
- Backend API running (see backend README)

### Installation

1. Navigate to the Flutter app directory:
```bash
cd app/flutter_application_1
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

### Configuration

1. Update the API base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = "http://127.0.0.1:8001";
```

For different environments:
- **Android Emulator**: `http://10.0.2.2:8001`
- **iOS Simulator**: `http://127.0.0.1:8001`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.100:8001`)

### Running the Application

1. Check available devices:
```bash
flutter devices
```

2. Run the app:
```bash
flutter run
```

Or specify a device:
```bash
flutter run -d <device-id>
```

### Building APK (Android)

To build an APK for testing:
```bash
flutter build apk
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── services/
│   └── api_service.dart        # API client
└── screens/
    ├── auth_provider.dart      # Authentication state management
    ├── login_screen.dart       # Login/Registration
    ├── home_screen.dart        # Main navigation
    ├── profile_screen.dart     # Passenger profile
    ├── flight_search_screen.dart
    ├── flight_details_screen.dart
    ├── seat_selection_screen.dart
    ├── booking_screen.dart
    ├── payment_screen.dart
    ├── my_trips_screen.dart
    ├── booking_detail_screen.dart
    ├── checkin_screen.dart
    ├── boarding_pass_screen.dart
    ├── announcements_screen.dart
    ├── staff_dashboard_screen.dart
    ├── staff_flights_screen.dart
    ├── staff_bookings_screen.dart
    └── staff_announcements_screen.dart
```

### Features

#### Passenger Features
- **Authentication**: Login and registration
- **Profile Management**: Complete passenger profile (required for booking)
- **Flight Search**: Search flights by origin, destination, and date
- **Flight Details**: View flight information and seat map
- **Seat Selection**: Visual seat map with seat selection
- **Booking**: Create bookings with multiple passengers
- **Payment**: Mock payment processing
- **My Trips**: View all bookings and trip details
- **Check-in**: Check in 24 hours to 1 hour before departure
- **Boarding Pass**: View digital boarding pass with QR code
- **Announcements**: View flight-related announcements

#### Staff Features
- **Dashboard**: Staff management dashboard
- **Flight Management**: View and manage flights
- **Booking Management**: View and search bookings by PNR
- **Announcements**: Create and manage announcements

### Dependencies

Key packages used:
- `http`: HTTP client for API calls
- `provider`: State management
- `shared_preferences`: Local storage for tokens
- `intl`: Date and time formatting

### Testing

1. **Login as Passenger**:
   - Email: `passenger@example.com`
   - Password: `pass123`

2. **Login as Staff**:
   - Email: `admin@airline.com`
   - Password: `admin123`

### Troubleshooting

**Connection Issues**:
- Ensure the backend is running
- Check the API base URL matches your environment
- For physical devices, ensure your device and computer are on the same network

**Build Issues**:
- Run `flutter clean` and `flutter pub get`
- Ensure you have the correct Flutter SDK version
- Check Android/iOS setup in Flutter documentation

### Notes

- The app requires a complete passenger profile before booking
- Seat holds expire after 10 minutes
- Check-in is only available 24 hours to 1 hour before departure
- All API calls include proper error handling and loading states
