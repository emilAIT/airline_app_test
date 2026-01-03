import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/api/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  bool loading = false;

  bool get isAuthenticated => user != null;

  Future<bool> login(String email, String password) async {
    loading = true;
    notifyListeners();

    final ok = await AuthApi.login(email, password);
    if (ok) {
      user = await AuthApi.fetchMe();
    }

    loading = false;
    notifyListeners();
    return ok;
  }

  void logout() {
    user = null;
    AuthApi.logout();
    notifyListeners();
  }

  Future<String?> register(String email, String password, String? fullName) async {
    loading = true;
    notifyListeners();

    final error = await AuthApi.register(email, password, fullName);
    if (error == null) {
      user = await AuthApi.fetchMe();
    }

    loading = false;
    notifyListeners();
    return error;
  }
}
