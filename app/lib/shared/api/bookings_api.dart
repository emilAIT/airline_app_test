import '../models/booking.dart';
import 'api_client.dart';

class BookingsApi {
  final ApiClient client;

  BookingsApi(this.client);

  Future<Booking> createBooking(Map<String, dynamic> bookingData) async {
    final response = await client.post('/bookings/', body: bookingData);
    return Booking.fromJson(response);
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await client.get('/bookings/my-bookings');
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> getBookingByPnr(String pnr) async {
    final response = await client.get('/bookings/$pnr');
    return Booking.fromJson(response);
  }

  Future<Booking> cancelBooking(int bookingId) async {
    final response = await client.post('/bookings/$bookingId/cancel');
    return Booking.fromJson(response);
  }
}

