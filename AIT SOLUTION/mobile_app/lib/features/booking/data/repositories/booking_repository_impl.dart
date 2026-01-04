import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/features/booking/domain/repositories/booking_repository.dart';
import 'package:ait_airlines/features/booking/domain/entities/booking.dart';
import 'package:ait_airlines/features/booking/data/models/booking_model.dart';

@LazySingleton(as: BookingRepository)
class BookingRepositoryImpl implements BookingRepository {
  final ApiClient _apiClient;

  BookingRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, Booking>> createBooking(
    int flightId,
    int passengersCount, {
    List<Map<String, dynamic>>? passengers,
  }) async {
    try {
      final response = await _apiClient.dio.post('/bookings/', data: {
        'flight_id': flightId,
        'passengers_count': passengersCount,
        if (passengers != null) 'passengers': passengers,
      });
      return Right(BookingModel.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data['detail'] ?? 'Failed to create booking'));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getMyBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings/');
      final List<dynamic> data = response.data;
      return Right(data.map((json) => BookingModel.fromJson(json)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data['detail'] ?? 'Failed to fetch bookings'));
    }
  }

  @override
  Future<Either<Failure, void>> processPayment(
      int bookingId, Map<String, dynamic> cardData) async {
    try {
      await _apiClient.dio.post('/bookings/$bookingId/pay', data: cardData);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
          ServerFailure(e.response?.data['detail'] ?? 'Payment failed'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkIn(int bookingId) async {
    try {
      // Проверяем, что токен установлен
      final token = await _apiClient.getStoredToken();
      if (token == null) {
        return Left(ServerFailure('Authentication required. Please log in again.'));
      }
      
      print('DEBUG checkIn: Making request for booking $bookingId');
      final response = await _apiClient.dio.post('/bookings/$bookingId/checking');
      
      final data = Map<String, dynamic>.from(response.data);
      print('DEBUG checkIn response: $data');
      
      // Проверяем, что backend вернул success: true
      if (data['success'] == false) {
        final reason = data['reason']?.toString() ?? 'Unknown error';
        final message = data['message']?.toString() ?? reason;
        return Left(ServerFailure(message));
      }
      
      return Right(data);
    } on DioException catch (e) {
      print('DEBUG checkIn DioException: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        // Очищаем токен и просим пользователя войти заново
        await _apiClient.clearAuthToken();
        return Left(ServerFailure('Session expired. Please log in again.'));
      }
      
      return Left(ServerFailure(e.response?.data['reason']?.toString() ??
          e.response?.data['detail']?.toString() ??
          e.message ??
          'Check-in failed'));
    } catch (e) {
      print('DEBUG checkIn Exception: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> cancelBooking(int bookingId) async {
    try {
      final response = await _apiClient.dio.post('/bookings/$bookingId/cancel');
      return Right(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['detail']?.toString() ??
          e.message ??
          'Cancellation failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTicketDetails(int bookingId) async {
    try {
      // Проверяем, что токен установлен
      final token = await _apiClient.getStoredToken();
      if (token == null) {
        return Left(ServerFailure('Authentication required. Please log in again.'));
      }
      
      print('DEBUG getTicketDetails: Making request for booking $bookingId');
      final response = await _apiClient.dio.get('/bookings/$bookingId/ticket-details');
      print('DEBUG getTicketDetails: Success response received');
      return Right(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      print('DEBUG getTicketDetails DioException: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        // Очищаем токен и просим пользователя войти заново
        await _apiClient.clearAuthToken();
        return Left(ServerFailure('Session expired. Please log in again.'));
      }
      
      return Left(ServerFailure(e.response?.data['detail']?.toString() ??
          e.message ??
          'Failed to get ticket details'));
    } catch (e) {
      print('DEBUG getTicketDetails Exception: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
