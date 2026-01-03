import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/enums.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isPassenger => _currentUser?.role == UserRole.PASSENGER;
  bool get isStaff => _currentUser?.role == UserRole.STAFF;

  Future<void> loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageService.instance.getToken();
      
      if (_token != null) {
        final userId = StorageService.instance.getUserId();
        final email = StorageService.instance.getUserEmail();
        final roleStr = StorageService.instance.getUserRole();

        if (userId != null && email != null && roleStr != null) {
          _currentUser = User(
            id: userId,
            email: email,
            role: UserRole.fromJson(roleStr),
          );
        } else {
          // Invalid stored data, clear it
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String token, User user) async {
    _token = token;
    _currentUser = user;

    await StorageService.instance.saveToken(token);
    await StorageService.instance.saveUserId(user.id);
    await StorageService.instance.saveUserEmail(user.email);
    await StorageService.instance.saveUserRole(user.role.toJson());

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    await StorageService.instance.clearAll();

    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}

