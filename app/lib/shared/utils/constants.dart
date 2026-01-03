class AppConstants {
  // API Configuration
  // For physical device testing, use your computer's IP address
  static const String baseUrl = 'http://10.177.46.137:8000';
  
  // For emulator, use: 'http://10.0.2.2:8000'
  // For localhost: 'http://localhost:8000'
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Seat hold duration (minutes)
  static const int seatHoldMinutes = 10;
  
  // Check-in window
  static const int checkInOpenHours = 24;
  static const int checkInCloseHours = 1;
  
  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPassengersPerBooking = 9;
}

