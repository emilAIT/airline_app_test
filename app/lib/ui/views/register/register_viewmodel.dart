import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.router.dart';
import '../../../app/app.locator.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class RegisterViewModel extends BaseViewModel {
  final _authService = locator<AuthService>();
  final NavigationService _navigationService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passportController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  RegisterViewModel({
    NavigationService? navigationService,
  }) : _navigationService = navigationService ?? NavigationService();

  Future<void> selectDateOfBirth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateOfBirth = picked;
      notifyListeners();
    }
  }

  Future<void> register() async {
    _errorMessage = null;
    notifyListeners();

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passportController.text.isEmpty ||
        nationalityController.text.isEmpty ||
        _dateOfBirth == null) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      final userRegister = UserRegister(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        passportNumber: passportController.text.trim(),
        nationality: nationalityController.text.trim(),
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
      );

      await _authService.register(userRegister);
      _navigationService.replaceWith(Routes.loginView);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    passportController.dispose();
    nationalityController.dispose();
    super.dispose();
  }
}
