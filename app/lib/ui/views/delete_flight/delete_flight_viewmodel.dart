import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class DeleteFlightViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final flightIdController = TextEditingController();

  FlightPublic? _flight;
  FlightPublic? get flight => _flight;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadFlight() async {
    if (flightIdController.text.trim().isEmpty) {
      _errorMessage = 'Please enter flight ID';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    _flight = null;
    notifyListeners();

    try {
      _flight = await _flightService.getFlight(flightIdController.text.trim());
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _flight = null;
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> deleteFlight() async {
    if (_flight == null) {
      _errorMessage = 'Please load flight first';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _flightService.deleteFlight(_flight!.id);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight deleted successfully')),
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

