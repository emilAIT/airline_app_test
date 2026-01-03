import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Автоматическое определение базового URL в зависимости от платформы
  // Для Web: localhost:8000
  // Для Android эмулятора: 10.0.2.2:8000
  // Для физического Android устройства: IP адрес компьютера (192.168.68.66)
  // Для iOS симулятора: localhost:8000
  static String get baseUrl {
    if (kIsWeb) {
      // Web browser - используем localhost
      return 'http://localhost:8000/api/v1';
    } else {
      // Mobile (Android/iOS) - используем IP адрес
      // Для Android эмулятора используйте: http://10.0.2.2:8000/api/v1
      // Для физического Android устройства используйте IP вашего компьютера
      return 'http://192.168.68.66:8000/api/v1';
    }
  }
  
  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login/access-token';
  static const String usersMe = '/users/me';
  static const String usersProfile = '/users/me/profile';
  static const String flightsSearch = '/flights/search';
  static const String flightDetails = '/flights';
  static const String flightSeats = '/flights';
  static const String flightHoldSeats = '/flights';
  static const String flightReleaseSeats = '/flights';
  static const String flightAnnouncements = '/flights';
  static const String bookings = '/bookings';
  static const String bookingsPay = '/bookings';
  static const String bookingsByPnr = '/bookings/by-pnr';
  static const String checkin = '/checkin';
  static const String boardingPass = '/checkin';
  static const String userNotifications = '/users/me/notifications';
  static const String userNotificationsUnreadCount = '/users/me/notifications/unread-count';
  static const String userNotificationMarkRead = '/users/me/notifications';
  static const String userNotificationsReadAll = '/users/me/notifications/read-all';
}


