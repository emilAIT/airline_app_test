import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool get isAuthenticated => _token != null;
  bool get isStaff => _user?['role'] == 'STAFF';

  final ApiService _api = ApiService();

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.login(email, password);
      if (response.containsKey('access_token')) {
        _token = response['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        // Get user info from token
        final role = _api.getRoleFromToken(_token!);
        _user = {'email': email, 'role': role ?? 'PASSENGER'};
        await prefs.setString('user', jsonEncode(_user));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    try {
      final response = await _api.register(email, password, fullName);
      // If registration succeeds, response will contain user data
      if (response.containsKey('id') || response.containsKey('email')) {
        // Auto login after registration
        return await login(email, password);
      }
      return false;
    } catch (e) {
      print("Registration error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
