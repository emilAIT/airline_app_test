import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class UpdateUserViewModel extends BaseViewModel {
  final UserService _userService = UserService();
  final NavigationService _navigationService = locator<NavigationService>();
  final UserPublic user;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  bool isActive = true;
  UserRole role = UserRole.passenger;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UpdateUserViewModel({required this.user}) {
    emailController.text = user.email;
    fullNameController.text = user.fullName ?? '';
    isActive = user.isActive;
    role = user.role;
  }

  Future<void> updateUser() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final update = UserUpdate(
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        password: passwordController.text.isEmpty ? null : passwordController.text,
        fullName: fullNameController.text.trim().isEmpty ? null : fullNameController.text.trim(),
        isActive: isActive,
        role: role,
      );

      await _userService.updateUser(user.id, update);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
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

