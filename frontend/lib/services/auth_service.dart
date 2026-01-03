import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

// Сервис для авторизации
class AuthService {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';

  static String? _token;
  static Map<String, dynamic>? _user;

  static String? get token => _token;
  static Map<String, dynamic>? get user => _user;
  static bool get isAuthenticated => _token != null;
  static bool get isStaff => _user?['role'] == 'STAFF';

  static Map<String, dynamic>? _parseJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String normalized = parts[1];
      normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return null;
      }

      final decoded = utf8.decode(base64.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) return payload;
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isTokenExpired(String token) {
    final payload = _parseJwtPayload(token);
    final exp = payload?['exp'];

    if (exp is int) {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSeconds;
    }
    if (exp is String) {
      final parsed = int.tryParse(exp);
      if (parsed == null) return false;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return parsed <= nowSeconds;
    }

    // If token has no exp, treat as non-expiring (best-effort).
    return false;
  }

  /// Restores persisted auth state on app start.
  /// Returns true when a valid token was loaded.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || savedToken.trim().isEmpty) {
      _token = null;
      _user = null;
      return false;
    }

    if (_isTokenExpired(savedToken)) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_userIdKey);
      _token = null;
      _user = null;
      return false;
    }

    final payload = _parseJwtPayload(savedToken);
    final role = payload?['role']?.toString();
    final sub = payload?['sub']?.toString();

    _token = savedToken;
    _user = {
      'email': prefs.getString(_emailKey),
      'role': role ?? prefs.getString(_roleKey),
      'id': int.tryParse(sub ?? '') ?? prefs.getInt(_userIdKey),
    };

    return true;
  }

  /// Alias for restoreSession() to match app bootstrap API.
  static Future<bool> init() => restoreSession();

  static String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
        if (detail is Map) {
          final inner = detail['detail'];
          if (inner is String && inner.trim().isNotEmpty) return inner;
        }
      }
    } catch (_) {
      // Not JSON or unexpected format.
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
  }

  /// Logs in and persists token.
  /// Returns null on success, otherwise an error message.
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        final msg = _extractErrorMessage(response.body);
        return msg ?? 'Ошибка входа (код ${response.statusCode})';
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return 'Не удалось получить токен';
      }

      final payload = _parseJwtPayload(accessToken);
      final roleFromJwt = payload?['role']?.toString();
      final userIdFromJwt = int.tryParse(payload?['sub']?.toString() ?? '');

      final userFromResponse = (data['user'] is Map) ? (data['user'] as Map) : null;

      _token = accessToken;
      _user = {
        'email': (userFromResponse?['email'] ?? email).toString(),
        'role': roleFromJwt ?? userFromResponse?['role']?.toString(),
        'id': userIdFromJwt ?? userFromResponse?['id'],
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, accessToken);
      await prefs.setString(_emailKey, _user?['email']?.toString() ?? email);
      if (_user?['role'] != null) {
        await prefs.setString(_roleKey, _user!['role'].toString());
      }
      final id = _user?['id'];
      if (id is int) {
        await prefs.setInt(_userIdKey, id);
      }

      return null;
    } catch (e) {
      return 'Ошибка сети: $e';
    }
  }

  static Future<String?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final accessToken = data['access_token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          return 'Регистрация прошла, но токен не получен';
        }

        final payload = _parseJwtPayload(accessToken);
        final roleFromJwt = payload?['role']?.toString();
        final userIdFromJwt = int.tryParse(payload?['sub']?.toString() ?? '');
        final userFromResponse = (data['user'] is Map) ? (data['user'] as Map) : null;

        _token = accessToken;
        _user = {
          'email': (userFromResponse?['email'] ?? email).toString(),
          'role': roleFromJwt ?? userFromResponse?['role']?.toString(),
          'id': userIdFromJwt ?? userFromResponse?['id'],
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, accessToken);
        await prefs.setString(_emailKey, _user?['email']?.toString() ?? email);
        if (_user?['role'] != null) {
          await prefs.setString(_roleKey, _user!['role'].toString());
        }
        final id = _user?['id'];
        if (id is int) {
          await prefs.setInt(_userIdKey, id);
        }

        return null;
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is List) {
          return data['detail'][0]['msg'];
        }
        return data['detail']?['detail'] ??
            'Ошибка регистрации (код ${response.statusCode})';
      }
    } catch (e) {
      return 'Ошибка сети: $e';
    }
  }

  static void logout() {
    _token = null;
    _user = null;

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_tokenKey);
      prefs.remove(_emailKey);
      prefs.remove(_roleKey);
      prefs.remove(_userIdKey);
    });
  }
}
