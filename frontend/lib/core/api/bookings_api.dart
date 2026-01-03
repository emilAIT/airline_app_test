import 'dart:convert';
import 'api_client.dart';
import '../../models/booking.dart';
import '../../models/ticket.dart';
import '../../models/seat.dart';

class BookingsApi {
  static Future<Booking?> createBooking(
    int flightId,
    List<String> seats,
  ) async {
    final res = await ApiClient.post('/bookings/', {
      'flight_id': flightId,
      'seats': seats,
    });

    if (res.statusCode == 200) {
      return Booking.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  static Future<List<Booking>> getUserBookings() async {
    final res = await ApiClient.get('/bookings/');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<Seat>> getSeatMap(int flightId) async {
    final res = await ApiClient.get('/flights/$flightId/seat-map');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Seat.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> holdSeats(int flightId, List<String> seats) async {
    final res = await ApiClient.post('/flights/$flightId/hold-seats/', {
      'seats': seats,
    });
    return res.statusCode == 200;
  }

  static Future<Ticket?> checkIn(int ticketId) async {
    final res = await ApiClient.post('/check-in/$ticketId', {});
    if (res.statusCode == 200) {
      return Ticket.fromJson(jsonDecode(res.body));
    }
    return null;
  }
}