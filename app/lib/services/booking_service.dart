import 'dart:convert';
import '../models/booking_model.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService;
  
  BookingService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<BookingPublic> createBooking(BookingCreate booking) async {
    try {
      final response = await _apiService.post(
        '/bookings',
        body: booking.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return BookingPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create booking error: $e');
    }
  }

  Future<List<BookingPublic>> getMyBookings({String? scope}) async {
    try {
      final queryParams = scope != null ? {'scope': scope} : null;
      final response = await _apiService.get(
        '/bookings/me',
        queryParams: queryParams,
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = BookingsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get bookings: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get bookings error: $e');
    }
  }

  Future<BookingPublic> getBooking(String bookingId) async {
    try {
      final response = await _apiService.get(
        '/bookings/$bookingId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return BookingPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get booking error: $e');
    }
  }

  Future<BookingPublic> cancelBooking(String bookingId) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/cancel',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return BookingPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to cancel booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Cancel booking error: $e');
    }
  }

  Future<BookingPublic> searchByPnr(String pnr) async {
    try {
      final response = await _apiService.get(
        '/bookings/search/by-pnr/$pnr',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return BookingPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to search booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Search booking error: $e');
    }
  }

  Future<List<BookingPublic>> getBookingsByFlight(String flightId) async {
    try {
      final response = await _apiService.get(
        '/bookings/flight/$flightId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = BookingsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get bookings: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get bookings error: $e');
    }
  }

  Future<List<BookingPublic>> getAllBookings({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/bookings/',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
          'args': '',
          'kwargs': '',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = BookingsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get all bookings: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get all bookings error: $e');
    }
  }
}

