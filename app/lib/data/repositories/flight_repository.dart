import '../../core/api_client.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_assets.dart';
import '../models/flight_model.dart';

abstract class FlightRepository {
  Future<List<Airport>> getAirports();
  Future<List<Flight>> searchFlights(
      int originId, int destinationId, String departureDate);
  Future<List<Flight>> listFlights();
  Future<Map<String, dynamic>> getFlightDetails(int flightId);
  Future<List<Map<String, dynamic>>> getAnnouncements();
}

class FlightRepositoryImpl implements FlightRepository {
  final ApiClient _apiClient;

  FlightRepositoryImpl(this._apiClient);

  @override
  Future<List<Airport>> getAirports() async {
    final response = await _apiClient.get('/passenger/airports');
    return (response as List)
        .map((json) => Airport(
              id: json['id'],
              code: json['code'],
              name: json['name'],
              city: json['city'],
              country: json['country'],
            ))
        .toList();
  }

  @override
  Future<List<Flight>> searchFlights(
      int originId, int destinationId, String departureDate) async {
    // Backend expects GET with query params
    final response = await _apiClient.get(
        '/passenger/flights/search?origin_id=$originId&destination_id=$destinationId&departure_date=$departureDate');

    return (response as List)
        .map((json) => FlightModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<Flight>> listFlights() async {
    final response = await _apiClient.get('/passenger/flights');
    return (response as List)
        .map((json) => FlightModel.fromJson(json))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getFlightDetails(int flightId) async {
    return await _apiClient.get('/passenger/flights/$flightId');
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final response = await _apiClient.get('/passenger/announcements');
    return List<Map<String, dynamic>>.from(response as List);
  }
}
