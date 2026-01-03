import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<TokenResponse> login(String email, String password) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.authLogin}';
    print('[AUTH] Login request to: $url');
    print('[AUTH] Email: $email');
    
    try {
      // OAuth2PasswordRequestForm ожидает application/x-www-form-urlencoded
      // Используем строку с правильно закодированными параметрами
      final formData = 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}';
      
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      print('[AUTH] Login response status: ${response.statusCode}');
      print('[AUTH] Login response data: ${response.data}');
      
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('[AUTH] Login error: ${e.type}');
      print('[AUTH] Login error message: ${e.message}');
      if (e.response != null) {
        print('[AUTH] Login error status: ${e.response?.statusCode}');
        print('[AUTH] Login error data: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e) {
      print('[AUTH] Login unexpected error: $e');
      rethrow;
    }
  }

  Future<User> register({
    required String email,
    required String password,
    String? fullName,
    String role = 'passenger',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.authRegister}',
        data: {
          'email': email,
          'password': password,
          if (fullName != null) 'full_name': fullName,
          'role': role,
        },
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser(String token) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.usersMe}';
    print('[AUTH] GetCurrentUser request to: $url');
    
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print('[AUTH] GetCurrentUser response status: ${response.statusCode}');
      
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print('[AUTH] GetCurrentUser error: ${e.type}');
      print('[AUTH] GetCurrentUser error message: ${e.message}');
      if (e.response != null) {
        print('[AUTH] GetCurrentUser error status: ${e.response?.statusCode}');
        print('[AUTH] GetCurrentUser error data: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e) {
      print('[AUTH] GetCurrentUser unexpected error: $e');
      rethrow;
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['detail'] ?? data['message'] ?? 'Unknown error';
        return message.toString();
      }
      return 'Server error: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection and ensure the backend server is running.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. For physical devices, use your computer\'s IP address instead of localhost.';
    } else {
      return 'Network error: ${error.message ?? 'Please check your connection'}';
    }
  }
}



