import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.router.dart';
import '../../../app/app.locator.dart';
import '../../../services/auth_service.dart';

class LoginViewModel extends BaseViewModel {
  final _authService = locator<AuthService>();
  final NavigationService _navigationService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginViewModel({
    NavigationService? navigationService,
  })  : _navigationService = navigationService ?? NavigationService();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> login() async {
    _errorMessage = null;
    notifyListeners();

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      _navigationService.replaceWith(Routes.flightSearchView);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void navigateToRegister() {
    _navigationService.navigateTo(Routes.registerView);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

