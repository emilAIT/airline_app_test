import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  
  AuthService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<Token> login(String username, String password) async {
    try {
      final formBody = 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}&grant_type=password';
      
      final response = await _apiService.post(
        '/login/access-token',
        formBody: formBody,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('AuthService: Login response body: $responseBody');
        
        if (responseBody.isEmpty) {
          throw Exception('Login failed: Empty response from server');
        }
        
        final jsonData = jsonDecode(responseBody);
        print('AuthService: Parsed JSON: $jsonData');
        
        if (jsonData['access_token'] == null) {
          throw Exception('Login failed: access_token is missing in response');
        }
        
        final token = Token.fromJson(jsonData);
        
        if (token.accessToken.isEmpty) {
          throw Exception('Login failed: access_token is empty');
        }
        
        await _apiService.saveToken(token.accessToken);
        // Save user email for fallback display
        await _apiService.saveUserEmail(username);
        print('AuthService: Saved user email: $username');
        return token;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<UserPublic> register(UserRegister userRegister) async {
    try {
      final response = await _apiService.post(
        '/users/signup',
        body: userRegister.toJson(),
      );

      if (response.statusCode == 200) {
        return UserPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<UserPublic> getCurrentUser() async {
    try {
      // Check if token exists
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        print('AuthService: No token found, redirecting to login');
        throw Exception('No authentication token found. Please login again.');
      }
      
      print('AuthService: Token found, requesting /users/me endpoint...');
      print('AuthService: Full URL will be: http://localhost:8000/api/v1/users/me');
      
      final response = await _apiService.get(
        '/users/me',
        requiresAuth: true,
      );

      print('AuthService: Response status code: ${response.statusCode}');
      print('AuthService: Response headers: ${response.headers}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('AuthService: Parsed user data: $userData');
        final user = UserPublic.fromJson(userData);
        print('AuthService: User created successfully - Email: ${user.email}, Role: ${user.role}');
        return user;
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be invalid
        print('AuthService: 401 Unauthorized, clearing token');
        await _apiService.clearToken();
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        // User not found - token might be invalid or user was deleted
        // Clear token and ask user to login again
        print('AuthService: 404 User not found, clearing token');
        await _apiService.clearToken();
        throw Exception('User not found. Your session may have expired. Please login again.');
      } else {
        print('AuthService: Unexpected status code ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      // If it's already our custom exception, rethrow it
      if (e.toString().contains('No authentication token') || 
          e.toString().contains('Authentication failed') ||
          e.toString().contains('User not found')) {
        print('AuthService: Re-throwing authentication error: $e');
        rethrow;
      }
      // Otherwise wrap it
      print('AuthService: Unexpected error getting user - $e');
      throw Exception('Get user error: $e');
    }
  }

  Future<PassengerProfilePublic?> getPassengerProfile() async {
    try {
      final response = await _apiService.get(
        '/users/me/profile',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return PassengerProfilePublic.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        // Profile doesn't exist yet
        return null;
      } else if (response.statusCode == 403) {
        // User is not a passenger (e.g., staff)
        return null;
      } else {
        print('AuthService: Failed to get passenger profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('AuthService: Error getting passenger profile: $e');
      return null;
    }
  }

  Future<String?> getCachedUserEmail() async {
    return await _apiService.getUserEmail();
  }

  Future<void> logout() async {
    try {
      // Always clear token and email locally
      await _apiService.clearToken();
    } catch (e) {
      // Always clear token and email locally, even if there's an error
      await _apiService.clearToken();
      print('AuthService: Logout error (token cleared locally): $e');
    }
  }
}

