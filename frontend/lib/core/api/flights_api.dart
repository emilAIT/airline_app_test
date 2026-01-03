import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/flight.dart';

class FlightsApi {
  static const String baseUrl = 'http://127.0.0.1:8000/flights';
  // для реального устройства: http://192.168.x.x:8000

  Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/search'
      '?origin_code=${origin.toUpperCase()}'
      '&destination_code=${destination.toUpperCase()}'
      '&departure_date=${date.toIso8601String().split('T').first}',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Flight.fromJson(e)).toList();
    }

    if (response.statusCode == 404) {
      return [];
    }

    throw Exception('Failed to load flights');
  }

  Future<List<Flight>> getAllFlights() async {
    final uri = Uri.parse('$baseUrl/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Flight.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load all flights');
    }
  }
}
