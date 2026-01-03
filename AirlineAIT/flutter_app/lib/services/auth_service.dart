// Authentication state management service.
//
// Extends ChangeNotifier for Provider integration.
// Manages JWT token storage, user data, and login/logout flows.
// Persists state to SharedPreferences.
//
// Part of: Flutter Frontend / Services
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  AuthService(this._prefs) {
    _token = _prefs.getString('access_token');
    _loadUserFromStorage();
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  void _loadUserFromStorage() {
    final userJson = _prefs.getString('user_data');
    if (userJson != null) {
      _user = Map<String, dynamic>.from(
        json.decode(userJson) as Map,
      );
    }
  }

  Future<bool> login(String email, String password, ApiService apiService) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.login(email, password);
      
      if (response.statusCode == 200) {
        _token = response.data['access_token'];
        _prefs.setString('access_token', _token!);
        apiService.updateToken(_token);
        
        // Get user info
        final userResponse = await apiService.getCurrentUser();
        _user = userResponse.data;
        _prefs.setString('user_data', json.encode(_user));
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Login Dio error: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
    } catch (e) {
      debugPrint('Login error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>> register(String email, String password, ApiService apiService, {String? role, int? assignedAirplaneId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.register(email, password, role: role, assignedAirplaneId: assignedAirplaneId);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // For STAFF, do not auto-login as approval is required
        if (role == 'STAFF') {
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'message': 'Registration successful. Pending approval.'};
        }

        // Auto login after registration
        final loginSuccess = await login(email, password, apiService);
        _isLoading = false;
        notifyListeners();
        return {'success': loginSuccess, 'message': loginSuccess ? 'Registration successful' : 'Registration successful but login failed'};
      }
    } catch (e) {
      debugPrint('Register error: $e');
      String errorMessage = 'Registration failed. Email may already be in use.';
      
      // Try to extract error message from response
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': errorMessage};
    }
    
    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Registration failed. Please try again.'};
  }

  void logout() {
    _token = null;
    _user = null;
    _prefs.remove('access_token');
    _prefs.remove('user_data');
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> userData) {
    _user = userData;
    _prefs.setString('user_data', const JsonCodec().encode(_user));
    notifyListeners();
  }
}

