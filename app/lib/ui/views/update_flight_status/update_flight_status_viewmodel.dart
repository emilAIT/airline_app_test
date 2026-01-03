import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class UpdateFlightStatusViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final flightIdController = TextEditingController();

  FlightStatus? _selectedStatus;
  FlightStatus? get selectedStatus => _selectedStatus;

  List<FlightStatus> get statuses => FlightStatus.values;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setStatus(String? value) {
    if (value != null) {
      _selectedStatus = FlightStatus.values.firstWhere(
        (status) => status.name == value,
      );
      notifyListeners();
    }
  }

  Future<void> updateStatus() async {
    if (flightIdController.text.trim().isEmpty) {
      _errorMessage = 'Please enter flight ID';
      notifyListeners();
      return;
    }

    if (_selectedStatus == null) {
      _errorMessage = 'Please select status';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _flightService.updateFlightStatus(
        flightIdController.text.trim(),
        FlightStatusUpdate(status: _selectedStatus!),
      );

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flight status updated successfully')),
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

