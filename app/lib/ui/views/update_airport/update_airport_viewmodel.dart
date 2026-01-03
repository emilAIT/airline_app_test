import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/airport_service.dart';
import '../../../models/airport_model.dart';

@StackedRoute()
class UpdateAirportViewArguments {
  final AirportPublic airport;
  UpdateAirportViewArguments({required this.airport});
}

class UpdateAirportViewModel extends BaseViewModel {
  final AirportService _airportService = AirportService();
  final NavigationService _navigationService = locator<NavigationService>();
  final AirportPublic airport;

  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UpdateAirportViewModel({required this.airport}) {
    codeController.text = airport.code;
    nameController.text = airport.name;
    cityController.text = airport.city;
    countryController.text = airport.country;
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> updateAirport() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final update = AirportUpdate(
        code: codeController.text.trim().isEmpty ? null : codeController.text.trim().toUpperCase(),
        name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
        country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
      );

      await _airportService.updateAirport(airport.id, update);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airport updated successfully')),
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
