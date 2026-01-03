import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/flight.dart';
import '../models/aviation.dart';

class FlightService {
  final Dio _dio;

  FlightService(this._dio);

  Future<List<Airport>> getAirports() async {
    try {
      final url = '${ApiConfig.baseUrl}/flights/airports';
      final response = await _dio.get(url);
      return (response.data as List)
          .map((json) => Airport.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Flight>> getAllFlights() async {
    try {
      // Use /all endpoint to get all flights
      final url = '${ApiConfig.baseUrl}/flights/all';
      final response = await _dio.get(url);
      return (response.data as List)
          .map((json) => Flight.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['detail'] ?? 'Unknown error';
        throw message.toString();
      } else {
        throw 'Network error. Please check your connection.';
      }
    }
  }

  Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final url = '${ApiConfig.baseUrl}/flights/search';
      
      final response = await _dio.get(
        url,
        queryParameters: {
          'origin': origin,
          'destination': destination,
          'date': dateStr,
        },
      );

      return (response.data as List)
          .map((json) => Flight.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flight> getFlightDetails(int flightId) async {
    try {
      final url = '${ApiConfig.baseUrl}/flights/$flightId';
      final response = await _dio.get(url);

      return Flight.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

      Future<List<SeatStatus>> getFlightSeats(int flightId, {String? token}) async {
        try {
          final url = '${ApiConfig.baseUrl}/flights/$flightId/seats';
          final options = token != null
              ? Options(headers: {'Authorization': 'Bearer $token'})
              : null;
          final response = await _dio.get(url, options: options);

          return (response.data as List)
              .map((json) => SeatStatus.fromJson(json))
              .toList();
        } on DioException catch (e) {
          throw _handleError(e);
        }
      }

      Future<DateTime> holdSeats(int flightId, List<String> seatNumbers, String token) async {
        try {
          final url = '${ApiConfig.baseUrl}/flights/$flightId/hold-seats';
          final response = await _dio.post(
            url,
            data: {'seat_numbers': seatNumbers},
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
          
          // Return the held_until datetime
          return DateTime.parse(response.data['held_until']);
        } on DioException catch (e) {
          throw _handleError(e);
        }
      }

      Future<void> releaseSeats(int flightId, List<String> seatNumbers, String token) async {
        try {
          final url = '${ApiConfig.baseUrl}/flights/$flightId/release-seats';
          await _dio.delete(
            url,
            queryParameters: {'seat_numbers': seatNumbers},
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
        } on DioException catch (e) {
          throw _handleError(e);
        }
      }

  Future<List<Announcement>> getFlightAnnouncements(int flightId, {String? token}) async {
    try {
      final url = '${ApiConfig.baseUrl}/flights/$flightId/announcements';
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.get(url, options: options);

      return (response.data as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['detail'] ?? 'Unknown error';
      return message.toString();
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}


