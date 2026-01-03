import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<DateTime?> holdSeats(int flightId, List<String> seatNumbers) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/passenger/flights/$flightId/hold-seats',
        data: {'seat_numbers': seatNumbers},
      );
      
      _isLoading = false;
      notifyListeners();
      
      final expiresAtStr = response.data['expires_at'] as String;
      return DateTime.parse(expiresAtStr);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Removed legacy createBooking to prioritize book-with-passengers flow


  Future<void> loadBookings({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      final response = await ApiService.get('/passenger/profile/trips');
      _bookings = (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners(); // Notify updates even if silent
      }
    } catch (e) {
      _error = e.toString();
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    // Don't set _isLoading = true here to avoid full screen spinner/flicker
    // Just perform the action and update the list.
    _error = null;
    // notifyListeners(); // Don't notify start, just result

    try {
      await ApiService.post('/passenger/bookings/$bookingId/cancel');
      await loadBookings(showLoading: false); // Reload list quietly
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkIn(int ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/passenger/check-in', data: {
        'ticket_id': ticketId,
      });
      _isLoading = false;
      notifyListeners();
      return response.data;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}



