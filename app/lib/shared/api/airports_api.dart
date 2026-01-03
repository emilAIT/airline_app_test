import '../models/airport.dart';
import 'api_client.dart';

class AirportsApi {
  final ApiClient client;

  AirportsApi(this.client);

  Future<List<Airport>> getAirports() async {
    final response = await client.get('/airports/');
    return (response as List).map((json) => Airport.fromJson(json)).toList();
  }
}

