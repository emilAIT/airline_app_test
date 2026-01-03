import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/announcement.dart';
import 'api_client.dart';
import '../storage/token_storage.dart';

class AnnouncementsApi {
  static Future<List<Announcement>> byFlight(int flightId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/announcements/flight/$flightId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Announcement.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  static Future<List<Announcement>> getGlobal() async {
    final url = Uri.parse('${ApiClient.baseUrl}/announcements/global');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Announcement.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load global announcements');
    }
  }

  static Future<Announcement> create({
    int? flightId,
    required String type,
    required String title,
    required String message,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${ApiClient.baseUrl}/announcements');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'flight_id': flightId,
        'type': type,
        'title': title,
        'message': message,
      }),
    );

    if (response.statusCode == 201) {
      return Announcement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create announcement: ${response.body}');
    }
  }
}