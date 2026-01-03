import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class CreateUserViewModel extends BaseViewModel {
  final UserService _userService = UserService();
  final NavigationService _navigationService = locator<NavigationService>();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  bool isActive = true;
  UserRole role = UserRole.passenger;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> createUser() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final userCreate = UserCreate(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim().isEmpty ? null : fullNameController.text.trim(),
        isActive: isActive,
        role: role,
      );

      await _userService.createUser(userCreate);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}

