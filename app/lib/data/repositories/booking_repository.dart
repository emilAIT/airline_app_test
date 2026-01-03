import '../../core/api_client.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';
import 'dart:math';

abstract class BookingRepository {
  Future<Booking> initiateBooking(int flightId, List<Map<String, dynamic>> passengers);
  Future<Booking> confirmBooking(int bookingId, String paymentMethod);
  Future<List<Booking>> getUpcomingTrips();
  Future<List<Booking>> getPastTrips();
  Future<List<Booking>> getMyTrips();
  Future<void> cancelBooking(int bookingId);
  Future<Map<String, dynamic>> checkIn(int ticketId);
  Future<Map<String, dynamic>> getBoardingPass(int ticketId);
}

class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _apiClient;

  BookingRepositoryImpl(this._apiClient);

  @override
  Future<Booking> initiateBooking(int flightId, List<Map<String, dynamic>> passengers) async {
    final response = await _apiClient.post(
      '/passenger/bookings',
      body: {
        'flight_id': flightId,
        'passengers': passengers,  // Changed from passenger_profiles to match backend
      },
    );
    return BookingModel.fromJson(response);
  }

  @override
  Future<Booking> confirmBooking(int bookingId, String paymentMethod) async {
    // Generate idempotency key for payment
    final idempotencyKey = 'KEY-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
    
    await _apiClient.post(
      '/passenger/bookings/$bookingId/payment',
      body: {
        'payment_method': paymentMethod,  // CARD, APPLE_PAY, or GOOGLE_PAY
        'idempotency_key': idempotencyKey,
      },
    );
    
    // Fetch the updated bookings to find the one we just confirmed
    final trips = await getUpcomingTrips();
    final booking = trips.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => throw Exception('Booking not found after payment'),
    );
    return booking;
  }

  @override
  Future<List<Booking>> getUpcomingTrips() async {
    final response = await _apiClient.get('/passenger/bookings/upcoming');
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<List<Booking>> getPastTrips() async {
    final response = await _apiClient.get('/passenger/bookings/past');
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<List<Booking>> getMyTrips() async {
    // Get all bookings from the new endpoint
    final response = await _apiClient.get('/passenger/bookings');
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await _apiClient.post('/passenger/bookings/$bookingId/cancel');
  }

  @override
  Future<Map<String, dynamic>> checkIn(int ticketId) async {
    return await _apiClient.post('/passenger/tickets/$ticketId/checkin');
  }

  @override
  Future<Map<String, dynamic>> getBoardingPass(int ticketId) async {
    return await _apiClient.get('/passenger/tickets/$ticketId/boarding-pass');
  }
}
