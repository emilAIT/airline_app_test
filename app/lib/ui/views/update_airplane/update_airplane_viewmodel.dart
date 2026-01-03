import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/airplane_service.dart';
import '../../../models/airplane_model.dart';

class UpdateAirplaneViewModel extends BaseViewModel {
  final AirplaneService _airplaneService = AirplaneService();
  final NavigationService _navigationService = locator<NavigationService>();
  final AirplanePublic airplane;

  final formKey = GlobalKey<FormState>();
  final modelController = TextEditingController();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UpdateAirplaneViewModel({required this.airplane}) {
    modelController.text = airplane.model;
  }

  Future<void> updateAirplane() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final update = AirplaneUpdate(
        model: modelController.text.trim(),
      );

      await _airplaneService.updateAirplane(airplane.id, update);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airplane updated successfully')),
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

