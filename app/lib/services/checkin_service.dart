import 'dart:convert';
import '../models/checkin_model.dart';
import 'api_service.dart';

class CheckInService {
  final ApiService _apiService;
  
  CheckInService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<CheckInPublic> createCheckIn(String ticketId) async {
    try {
      final response = await _apiService.post(
        '/checkins',
        body: {'ticket_id': ticketId},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return CheckInPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create check-in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create check-in error: $e');
    }
  }

  Future<CheckInPublic> getCheckIn(String checkinId) async {
    try {
      final response = await _apiService.get(
        '/checkins/$checkinId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return CheckInPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get check-in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get check-in error: $e');
    }
  }

  Future<List<CheckInPublic>> getCheckInsByBooking(String bookingId) async {
    try {
      final response = await _apiService.get(
        '/checkins/booking/$bookingId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = CheckInsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get check-ins: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get check-ins error: $e');
    }
  }

  Future<List<CheckInPublic>> getCheckInsByFlight(String flightId) async {
    try {
      final response = await _apiService.get(
        '/checkins/flight/$flightId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = CheckInsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get check-ins: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get check-ins error: $e');
    }
  }

  Future<BoardingPassPublic> getBoardingPass(String checkinId) async {
    try {
      final response = await _apiService.get(
        '/checkins/$checkinId/boarding-pass',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return BoardingPassPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get boarding pass: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get boarding pass error: $e');
    }
  }
}

