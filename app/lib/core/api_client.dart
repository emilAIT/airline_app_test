import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  final http.Client _client;
  static const String _tokenKey = 'access_token';

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders({bool requiresToken = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresToken) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresToken = true}) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresToken: requiresToken),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException('Request timeout - check your network connection and backend URL');
        },
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or backend is unreachable');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool requiresToken = true}) async {
    try {
      final response = await _client.post(
        Uri.parse('${Config.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresToken: requiresToken),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException('Request timeout - check your network connection and backend URL');
        },
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or backend is unreachable');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool requiresToken = true}) async {
    try {
      final response = await _client.put(
        Uri.parse('${Config.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresToken: requiresToken),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException('Request timeout - check your network connection and backend URL');
        },
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or backend is unreachable');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresToken = true}) async {
    try {
      final response = await _client.delete(
        Uri.parse('${Config.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresToken: requiresToken),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException('Request timeout - check your network connection and backend URL');
        },
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or backend is unreachable');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    switch (response.statusCode) {
      case 401:
        throw ApiException('Unauthorized', statusCode: 401, body: body);
      case 403:
        throw ApiException('Forbidden', statusCode: 403, body: body);
      case 404:
        throw ApiException('Not Found', statusCode: 404, body: body);
      case 409:
        throw ApiException('Conflict', statusCode: 409, body: body);
      case 422:
        throw ApiException('Validation Error', statusCode: 422, body: body);
      default:
        throw ApiException(
          'Something went wrong',
          statusCode: response.statusCode,
          body: body,
        );
    }
  }
}
