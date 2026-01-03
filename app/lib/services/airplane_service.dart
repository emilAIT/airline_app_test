import 'dart:convert';
import '../models/airplane_model.dart';
import 'api_service.dart';

class AirplaneService {
  final ApiService _apiService;
  
  AirplaneService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<AirplanePublic>> getAirplanes() async {
    try {
      final response = await _apiService.get('/airplanes');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AirplanePublic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get airplanes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get airplanes error: $e');
    }
  }

  Future<AirplanePublic> getAirplane(String airplaneId) async {
    try {
      final response = await _apiService.get('/airplanes/$airplaneId');

      if (response.statusCode == 200) {
        return AirplanePublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get airplane: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get airplane error: $e');
    }
  }

  Future<AirplanePublic> createAirplane(AirplaneCreateRequest request) async {
    try {
      final response = await _apiService.post(
        '/airplanes',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AirplanePublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create airplane: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create airplane error: $e');
    }
  }

  Future<AirplanePublic> updateAirplane(String airplaneId, AirplaneUpdate update) async {
    try {
      final response = await _apiService.put(
        '/airplanes/$airplaneId',
        body: update.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AirplanePublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update airplane: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update airplane error: $e');
    }
  }

  Future<void> deleteAirplane(String airplaneId) async {
    try {
      final response = await _apiService.delete(
        '/airplanes/$airplaneId',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete airplane: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete airplane error: $e');
    }
  }

  Future<AirplaneSeatMapResponse> getSeatMap(String airplaneId) async {
    try {
      final response = await _apiService.get(
        '/airplanes/$airplaneId/seat-map',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AirplaneSeatMapResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get seat map: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get seat map error: $e');
    }
  }
}

