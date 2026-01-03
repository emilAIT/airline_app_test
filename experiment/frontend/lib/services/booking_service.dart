import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/booking.dart';

class BookingService {
  final Dio _dio;

  BookingService(this._dio);

  Future<Booking> createBooking({
    required String token,
    required BookingCreate bookingData,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.bookings}',
        data: bookingData.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> payBooking({
    required String token,
    required int bookingId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.bookingsPay}/$bookingId/pay',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Booking>> getMyBookings({
    required String token,
    bool? future,
    bool? past,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (future != null) queryParams['future'] = future;
      if (past != null) queryParams['past'] = past;

      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.bookings}/me',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> getBookingDetails({
    required String token,
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.bookings}/$bookingId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get booking by PNR code and last name (no authentication required)
  /// Similar to Turkish Airlines booking management
  Future<Booking> getBookingByPnr({
    required String pnr,
    required String lastName,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.bookingsByPnr}/$pnr',
        queryParameters: {
          'last_name': lastName,
        },
      );

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BoardingPass>> checkIn({
    required String token,
    required int bookingId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.checkin}/$bookingId/checkin',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return (response.data as List)
          .map((json) => BoardingPass.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BoardingPass>> getBoardingPass({
    required String token,
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.boardingPass}/$bookingId/boarding-pass',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return (response.data as List)
          .map((json) => BoardingPass.fromJson(json))
          .toList();
    } on DioException catch (e) {
      // If user hasn't checked in yet (400 or 404), return empty list instead of throwing
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['detail']?.toString().toLowerCase() ?? '';
        
        if (statusCode == 400 || statusCode == 404 || 
            message.contains('not checked in') || 
            message.contains('checked in yet')) {
          // User hasn't checked in yet - return empty list
          return [];
        }
      }
      // For other errors, throw exception
      throw _handleError(e);
    }
  }

  Future<void> cancelBooking({
    required String token,
    required int bookingId,
  }) async {
    try {
      await _dio.delete(
        '${ApiConfig.baseUrl}${ApiConfig.bookings}/$bookingId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
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


