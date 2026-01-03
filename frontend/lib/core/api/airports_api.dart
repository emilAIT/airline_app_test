import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/airport.dart';

class AirportsApi {
  static const String baseUrl = 'http://127.0.0.1:8000/airports';

  Future<List<Airport>> getAllAirports() async {
    final uri = Uri.parse('$baseUrl/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Airport.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load airports');
    }
  }
}
