import 'dart:convert';
import '../models/airport_model.dart';
import '../models/flight_model.dart';
import '../models/seat_model.dart';
import 'api_service.dart';

class FlightService {
  final ApiService _apiService;
  
  FlightService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

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

  Future<List<FlightSearchResult>> searchFlights({
    required String originAirportId,
    required String destinationAirportId,
    required DateTime departureDateFrom,
    DateTime? departureDateTo,
  }) async {
    try {
      final queryParams = {
        'origin_airport_id': originAirportId,
        'destination_airport_id': destinationAirportId,
        'departure_date_from': departureDateFrom.toIso8601String().split('T')[0],
      };
      
      if (departureDateTo != null) {
        queryParams['departure_date_to'] = departureDateTo.toIso8601String().split('T')[0];
      }
      
      print('FlightService: Searching flights with parameters:');
      print('  - Origin Airport ID: $originAirportId');
      print('  - Destination Airport ID: $destinationAirportId');
      print('  - Departure Date From: ${departureDateFrom.toIso8601String().split('T')[0]}');
      if (departureDateTo != null) {
        print('  - Departure Date To: ${departureDateTo.toIso8601String().split('T')[0]}');
      } else {
        print('  - Departure Date To: Not specified (single date search)');
      }
      print('  - Query params: $queryParams');
      
      final response = await _apiService.get(
        '/flights/search',
        queryParams: queryParams,
      );
      
      print('FlightService: Response status code: ${response.statusCode}');
      print('FlightService: Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // If response is a list, return it
        if (data is List) {
          final results = data.map((json) => FlightSearchResult.fromJson(json)).toList();
          print('FlightService: Found ${results.length} flights');
          if (results.isNotEmpty) {
            print('FlightService: First flight: ${results.first.flightNumber} - ${results.first.departureTime}');
          }
          return results;
        }
        // If response is empty or null, return empty list
        print('FlightService: Response is not a list, returning empty list');
        return [];
      } else if (response.statusCode == 404) {
        // If no flights found, return empty list instead of throwing error
        print('FlightService: No flights found (404)');
        return [];
      } else {
        print('FlightService: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search flights: ${response.body}');
      }
    } catch (e) {
      // If it's already our exception, re-throw it
      if (e.toString().contains('Failed to search flights')) {
        rethrow;
      }
      throw Exception('Search flights error: $e');
    }
  }

  Future<FlightPublic> getFlight(String flightId) async {
    try {
      final response = await _apiService.get('/flights/$flightId');

      if (response.statusCode == 200) {
        return FlightPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get flight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get flight error: $e');
    }
  }

  Future<List<FlightPublic>> getFlights({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/flights',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = FlightsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get flights: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get flights error: $e');
    }
  }

  Future<FlightPublic> createFlight(FlightCreate flightCreate) async {
    try {
      final response = await _apiService.post(
        '/flights',
        body: flightCreate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return FlightPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create flight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create flight error: $e');
    }
  }

  Future<FlightPublic> updateFlight(String flightId, FlightUpdate flightUpdate) async {
    try {
      final response = await _apiService.put(
        '/flights/$flightId',
        body: flightUpdate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return FlightPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update flight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update flight error: $e');
    }
  }

  Future<void> deleteFlight(String flightId) async {
    try {
      final response = await _apiService.delete(
        '/flights/$flightId',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete flight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete flight error: $e');
    }
  }

  Future<FlightPublic> updateFlightStatus(String flightId, FlightStatusUpdate statusUpdate) async {
    try {
      final response = await _apiService.patch(
        '/flights/$flightId/status',
        body: statusUpdate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return FlightPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update flight status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update flight status error: $e');
    }
  }

  Future<FlightPublic> updateFlightGateTerminal(String flightId, FlightGateTerminalUpdate gateTerminalUpdate) async {
    try {
      final response = await _apiService.patch(
        '/flights/$flightId/gate-terminal',
        body: gateTerminalUpdate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return FlightPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update gate/terminal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update gate/terminal error: $e');
    }
  }

  Future<SeatMapResponse> getSeatMap(String flightId) async {
    try {
      final response = await _apiService.get('/flights/$flightId/seat-map');

      if (response.statusCode == 200) {
        return SeatMapResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get seat map: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get seat map error: $e');
    }
  }
}

