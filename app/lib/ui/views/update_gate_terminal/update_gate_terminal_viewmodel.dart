import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class UpdateGateTerminalViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final flightIdController = TextEditingController();
  final gateController = TextEditingController();
  final terminalController = TextEditingController();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> updateGateTerminal() async {
    if (flightIdController.text.trim().isEmpty) {
      _errorMessage = 'Please enter flight ID';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _flightService.updateFlightGateTerminal(
        flightIdController.text.trim(),
        FlightGateTerminalUpdate(
          gate: gateController.text.trim().isEmpty
              ? null
              : gateController.text.trim(),
          terminal: terminalController.text.trim().isEmpty
              ? null
              : terminalController.text.trim(),
        ),
      );

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gate/Terminal updated successfully')),
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

