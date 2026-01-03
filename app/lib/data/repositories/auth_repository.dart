import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<void> register(String email, String username, String password);
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  static const String _tokenKey = 'access_token';

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<User> login(String username, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'username': username, 'password': password},
      requiresToken: false,
    );
    
    final token = response['access_token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    return await getCurrentUser() ?? (throw ApiException('User not found after login'));
  }

  @override
  Future<void> register(String email, String username, String password) async {
    await _apiClient.post(
      '/auth/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'role': 'passenger',
      },
      requiresToken: false,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}
