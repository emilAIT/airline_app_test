import 'dart:convert';
import '../models/airport_model.dart';
import 'api_service.dart';

class AirportService {
  final ApiService _apiService;
  
  AirportService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<AirportPublic>> getAirports({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/airports/',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = AirportsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get airports: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get airports error: $e');
    }
  }

  Future<AirportPublic> getAirport(String airportId) async {
    try {
      final response = await _apiService.get('/airports/$airportId');

      if (response.statusCode == 200) {
        return AirportPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get airport: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get airport error: $e');
    }
  }

  Future<AirportPublic> createAirport(AirportCreate airportCreate) async {
    try {
      final response = await _apiService.post(
        '/airports/',
        body: airportCreate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AirportPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create airport: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create airport error: $e');
    }
  }

  Future<AirportPublic> updateAirport(String airportId, AirportUpdate update) async {
    try {
      final response = await _apiService.put(
        '/airports/$airportId',
        body: update.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return AirportPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update airport: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update airport error: $e');
    }
  }

  Future<void> deleteAirport(String airportId) async {
    try {
      final response = await _apiService.delete(
        '/airports/$airportId',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete airport: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete airport error: $e');
    }
  }
}

