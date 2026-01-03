import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String _tokenKey = 'access_token';
  static const String _userEmailKey = 'user_email';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
  }

  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<Map<String, String>> getHeaders({bool requiresAuth = false, String? contentType}) async {
    final headers = <String, String>{
      'Content-Type': contentType ?? 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('ApiService: Authorization header set with token (length: ${token.length})');
      } else {
        print('ApiService: WARNING - No token found for authenticated request!');
      }
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await getHeaders(requiresAuth: requiresAuth);
    
    print('ApiService: GET request to: $uri');
    print('ApiService: Headers: ${headers.keys.toList()}');

    return await http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = false,
    String? formBody,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final contentType = formBody != null 
        ? 'application/x-www-form-urlencoded' 
        : 'application/json';
    final defaultHeaders = await getHeaders(
      requiresAuth: requiresAuth,
      contentType: headers?['Content-Type'] ?? contentType,
    );
    if (headers != null) {
      defaultHeaders.addAll(headers);
      defaultHeaders.remove('Content-Type');
      defaultHeaders['Content-Type'] = headers['Content-Type'] ?? contentType;
    }

    return await http.post(
      uri,
      headers: defaultHeaders,
      body: formBody ?? (body != null ? jsonEncode(body) : null),
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await http.delete(uri, headers: headers);
  }
}

