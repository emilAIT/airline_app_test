import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiClient {
  static const baseUrl = 'http://127.0.0.1:8000';

  static Future<http.Response> get(String path) async {
    final token = await TokenStorage.getToken();
    return http.get(Uri.parse('$baseUrl$path'), headers: _headers(token));
  }

  static Future<http.Response> post(String path, Map data) async {
    final token = await TokenStorage.getToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> put(String path, Map data) async {
    final token = await TokenStorage.getToken();
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}