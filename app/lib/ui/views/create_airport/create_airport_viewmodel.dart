import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/airport_service.dart';
import '../../../models/airport_model.dart';

class CreateAirportViewModel extends BaseViewModel {
  final AirportService _airportService = AirportService();
  final NavigationService _navigationService = locator<NavigationService>();

  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> createAirport() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final airportCreate = AirportCreate(
        code: codeController.text.trim().toUpperCase(),
        name: nameController.text.trim(),
        city: cityController.text.trim(),
        country: countryController.text.trim(),
      );

      await _airportService.createAirport(airportCreate);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airport created successfully')),
        );
        _navigationService.back();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}
