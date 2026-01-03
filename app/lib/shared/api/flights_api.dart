import '../models/flight.dart';
import '../models/seat.dart';
import 'api_client.dart';

class FlightsApi {
  final ApiClient client;

  FlightsApi(this.client);

  Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
  }) async {
    final response = await client.get(
      '/flights/search?origin=$origin&destination=$destination&departure_date=$departureDate',
    );
    return (response as List).map((json) => Flight.fromJson(json)).toList();
  }

  Future<Flight> getFlight(int flightId) async {
    final response = await client.get('/flights/$flightId');
    return Flight.fromJson(response);
  }

  Future<SeatMap> getSeatMap(int flightId) async {
    final response = await client.get('/flights/$flightId/seats');
    return SeatMap.fromJson(response);
  }
}

