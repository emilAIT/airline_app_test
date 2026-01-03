import 'dart:convert';
import 'api_client.dart';
import '../storage/token_storage.dart';
import '../../models/user.dart';

class AuthApi {
  static Future<bool> login(String email, String password) async {
    final res = await ApiClient.post('/login', {
      'email': email,
      'password': password,
    });

    if (res.statusCode == 200) {
      final token = jsonDecode(res.body)['access_token'];
      await TokenStorage.saveToken(token);
      return true;
    }
    return false;
  }

  static Future<User> fetchMe() async {
    final res = await ApiClient.get('/me');
    return User.fromJson(jsonDecode(res.body));
  }

  static Future<String?> register(String email, String password, String? fullName) async {
    final res = await ApiClient.post('/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
    });

    if (res.statusCode == 200 || res.statusCode == 201) {
      final token = jsonDecode(res.body)['access_token'];
      await TokenStorage.saveToken(token);
      return null;
    }
    
    try {
      final body = jsonDecode(res.body);
      return body['detail']?.toString() ?? 'Registration failed';
    } catch (_) {
      return 'Registration failed: ${res.statusCode}';
    }
  }

  static Future<void> logout() async {
    await TokenStorage.clear();
  }
}