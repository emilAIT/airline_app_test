import 'dart:convert';
import '../models/seat_hold_model.dart';
import 'api_service.dart';

class SeatHoldService {
  final ApiService _apiService;
  
  SeatHoldService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<SeatHoldPublic> createSeatHold(String flightId, String flightSeatId) async {
    try {
      final response = await _apiService.post(
        '/seat-holds',
        body: {
          'flight_id': flightId,
          'flight_seat_id': flightSeatId,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return SeatHoldPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create seat hold: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create seat hold error: $e');
    }
  }

  Future<List<SeatHoldPublic>> getHoldsByFlight(String flightId) async {
    try {
      final response = await _apiService.get(
        '/seat-holds/flight/$flightId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = SeatHoldsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get seat holds: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get seat holds error: $e');
    }
  }

  Future<void> releaseSeatHold(String flightSeatId) async {
    try {
      final response = await _apiService.delete(
        '/seat-holds/$flightSeatId',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to release seat hold: ${response.body}');
      }
    } catch (e) {
      throw Exception('Release seat hold error: $e');
    }
  }

  Future<void> cleanupExpiredHolds() async {
    try {
      final response = await _apiService.post(
        '/seat-holds/cleanup',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cleanup expired holds: ${response.body}');
      }
    } catch (e) {
      throw Exception('Cleanup expired holds error: $e');
    }
  }
}

