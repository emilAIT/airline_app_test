```bash
cd flutter_app
flutter pub get
```

Edit `lib/shared/utils/constants.dart`:
- Android Emulator: `static const String baseUrl = 'http://10.0.2.2:8000';`
- Physical Device: `static const String baseUrl = 'http://YOUR_IP:8000';`
- iOS Simulator: `static const String baseUrl = 'http://localhost:8000';`

```bash
flutter run
```