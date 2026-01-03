# Quick Start Guide - ELDIK AirLines

## Prerequisites

1. **Python 3.10+** installed
2. **Flutter SDK** (3.10.4+) installed
3. **Backend API** must be running before starting the Flutter app

## Step 1: Start the Backend API

### Option A: Using Virtual Environment (Recommended)

```bash
# Navigate to backend directory
cd backend

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Navigate to app directory
cd app

# Start the FastAPI server
python main.py
```

3. **✅ Backend is running when you see:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

4. **🌐 Verify backend is working:**
- Open browser: http://127.0.0.1:8000/docs
- You should see Swagger API documentation

### Seed the Database (Required for Features)

In a **new terminal**, run:

```bash
cd backend
python seed_realistic_announcements.py
```

This creates:
- **Photos & Media System** data
- Realistic announcements and flights
- Test users:
  - **Staff**: `admin@eldiyar.com` / `password123`
  - **Passenger**: `passenger@example.com` / `pass123`

---

## Step 2: Configure Flutter App API URL

### Check Current API URL

Open: `app/flutter_application_1/lib/services/api_service.dart`

Find line 9:
```dart
static const String baseUrl = "http://127.0.0.1:8000";
```

### Update Based on Your Platform:

**For Android Emulator:**
```dart
static const String baseUrl = "http://10.0.2.2:8000";
```

**For iOS Simulator:**
```dart
static const String baseUrl = "http://127.0.0.1:8000";
```

**For Physical Device:**
1. Find your computer's IP address:
   - **macOS/Linux**: Run `ifconfig` or `ip addr`
   - **Windows**: Run `ipconfig`
   - Look for IPv4 address (e.g., `192.168.1.100`)

2. Update the URL:
```dart
static const String baseUrl = "http://192.168.1.100:8001";
```

**⚠️ Important:** Make sure your phone and computer are on the **same Wi-Fi network**.

---

## Step 3: Run the Flutter App

### Navigate to Flutter App Directory

```bash
cd app/flutter_application_1
```

### Install Dependencies

```bash
flutter pub get
```

### Check Available Devices

```bash
flutter devices
```

You should see something like:
```
2 connected devices:
• iPhone 15 Pro (mobile) • 12345678-1234-1234-1234-123456789012 • ios
• Chrome (web)           • chrome                                • web
```

### Run the App

**Option 1: Run on First Available Device**
```bash
flutter run
```

**Option 2: Run on Specific Device**
```bash
flutter run -d <device-id>
```

**Option 3: Run on Android Emulator**
```bash
flutter run -d android
```

**Option 4: Run on iOS Simulator**
```bash
flutter run -d ios
```

---

## Step 4: Test the App

### Login Credentials

**As Passenger:**
- Email: `test@eldiyar.com`
- Password: `password123`

**As Staff:**
- Email: `admin@eldiyar.com`
- Password: `password123`
### What to Test

1. **Login Screen**: See the rotating globe animation
2. **Home Screen**: Navigate to different sections
3. **Flight Search**: Search for flights
4. **Booking Flow**: Create a booking
5. **My Trips**: View your bookings
6. **Check-in**: Check in for a flight
7. **Boarding Pass**: View the futuristic boarding pass

---

## Troubleshooting

### Backend Connection Issues

**Error: "Connection refused" or "Failed to connect"**

1. **Check if backend is running:**
   ```bash
   curl http://127.0.0.1:8001/
   ```
   Should return: `{"message":"Airline Booking & Operations API",...}`

2. **Check API URL in Flutter:**
   - Verify `baseUrl` in `api_service.dart` matches your platform

3. **For Physical Device:**
   - Ensure phone and computer are on same Wi-Fi
   - Check firewall isn't blocking port 8001
   - Try disabling VPN if active

### Flutter Build Issues

**Error: "No devices found"**

1. **Start an emulator/simulator:**
   - Android: Open Android Studio → AVD Manager → Start emulator
   - iOS: Open Xcode → Window → Devices and Simulators → Start simulator

2. **Check Flutter setup:**
   ```bash
   flutter doctor
   ```
   Fix any issues shown

**Error: "Package not found"**

```bash
cd app/flutter_application_1
flutter clean
flutter pub get
```

### Database Issues

**Error: "No flights found" or empty data**

1. **Re-seed the database:**
   ```bash
   cd backend
   python seed.py
   ```

2. **Check database file exists:**
   ```bash
   ls backend/airline.db
   ```

---

## Development Tips

### Hot Reload
While app is running, press:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit

### View Logs
```bash
flutter logs
```

### Build APK (Android)
```bash
cd app/flutter_application_1
flutter build apk
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## Quick Command Reference

```bash
# Terminal 1: Start Backend
cd backend/app
uvicorn main:app --reload --port 8001

# Terminal 2: Run Flutter App
cd flutter
flutter run

# Terminal 3: Seed Database (if needed)
cd backend
python seed.py
```

---

## Need Help?

1. **Backend not starting?**
   - Check Python version: `python --version` (should be 3.10+)
   - Check dependencies: `pip list | grep fastapi`

2. **Flutter not running?**
   - Run `flutter doctor` to diagnose issues
   - Check Flutter version: `flutter --version`

3. **API connection issues?**
   - Test backend directly: http://127.0.0.1:8001/docs
   - Check network connectivity
   - Verify API URL in `api_service.dart`

---

## Success Indicators

✅ **Backend is ready when:**
- Server shows "Application startup complete"
- http://127.0.0.1:8001/docs opens in browser

✅ **Flutter app is ready when:**
- App launches on device/emulator
- Login screen shows rotating globe
- You can log in with test credentials

🎉 **You're all set!** Enjoy exploring Eldiyar Air!

