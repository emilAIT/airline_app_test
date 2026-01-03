import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _keyProfile = 'user_profile';
  static const String _keyBookings = 'user_bookings';
  static const String _keyLastSearch = 'last_search';

  // Profile Methods
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _prefs.setString(_keyProfile, jsonEncode(profile));
  }

  Map<String, dynamic>? getProfile() {
    final String? profileStr = _prefs.getString(_keyProfile);
    if (profileStr == null) return null;
    return jsonDecode(profileStr);
  }

  // Booking Methods
  Future<void> saveBooking(Map<String, dynamic> booking) async {
    final List<Map<String, dynamic>> bookings = getBookings();
    bookings.add(booking);
    await _prefs.setString(_keyBookings, jsonEncode(bookings));
  }

  List<Map<String, dynamic>> getBookings() {
    final String? bookingsStr = _prefs.getString(_keyBookings);
    if (bookingsStr == null) return [];
    final List<dynamic> decoded = jsonDecode(bookingsStr);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> updateBookingStatus(String pnr, String newStatus) async {
    final List<Map<String, dynamic>> bookings = getBookings();
    final index = bookings.indexWhere((b) => b['pnr'] == pnr);
    if (index != -1) {
      bookings[index]['status'] = newStatus;
      await _prefs.setString(_keyBookings, jsonEncode(bookings));
    }
  }
  
  // Last Search Methods
  Future<void> saveLastSearch(Map<String, dynamic> searchParams) async {
    await _prefs.setString(_keyLastSearch, jsonEncode(searchParams));
  }
  
  Map<String, dynamic>? getLastSearch() {
    final String? searchStr = _prefs.getString(_keyLastSearch);
    if (searchStr == null) return null;
    return jsonDecode(searchStr);
  }
}
