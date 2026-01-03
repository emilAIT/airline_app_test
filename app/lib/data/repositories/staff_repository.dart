import '../../core/api_client.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_assets.dart';
import '../../domain/entities/booking.dart';
import '../models/flight_model.dart';
import '../models/booking_model.dart';

abstract class StaffRepository {
  Future<List<Flight>> getAllFlights();
  Future<List<Airplane>> getAllAirplanes();
  Future<List<Booking>> getAllBookings();
  Future<void> updateFlight(int flightId, Map<String, dynamic> data);
  Future<void> cancelBooking(int bookingId);
  Future<Booking> getBookingByPnr(String pnr);
}

class StaffRepositoryImpl implements StaffRepository {
  final ApiClient _apiClient;

  StaffRepositoryImpl(this._apiClient);

  @override
  Future<List<Flight>> getAllFlights() async {
    final response = await _apiClient.get('/staff/flights');
    return (response as List).map((json) => FlightModel.fromJson(json)).toList();
  }

  @override
  Future<List<Airplane>> getAllAirplanes() async {
    final response = await _apiClient.get('/staff/airplanes');
    return (response as List).map((json) => AirplaneModel.fromJson(json)).toList();
  }

  @override
  Future<List<Booking>> getAllBookings() async {
    final response = await _apiClient.get('/staff/bookings');
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateFlight(int flightId, Map<String, dynamic> data) async {
    await _apiClient.put('/staff/flights/$flightId', body: data);
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await _apiClient.delete('/staff/bookings/$bookingId');
  }

  @override
  Future<Booking> getBookingByPnr(String pnr) async {
    final response = await _apiClient.get('/staff/bookings?pnr=$pnr');
    // API returns a list, get first item
    final bookings = (response as List).map((json) => BookingModel.fromJson(json)).toList();
    if (bookings.isEmpty) {
      throw Exception('Booking not found');
    }
    return bookings.first;
  }
}
