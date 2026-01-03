import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class UpdateFlightSimpleViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final formKey = GlobalKey<FormState>();

  final flightIdController = TextEditingController();
  final gateController = TextEditingController();
  final terminalController = TextEditingController();
  final airplaneIdController = TextEditingController();

  DateTime? _selectedDepartureTime;
  DateTime? get selectedDepartureTime => _selectedDepartureTime;

  DateTime? _selectedArrivalTime;
  DateTime? get selectedArrivalTime => _selectedArrivalTime;

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

  Future<void> selectDepartureTime(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDepartureTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDepartureTime ?? DateTime.now(),
        ),
      );
      if (time != null) {
        _selectedDepartureTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        notifyListeners();
      }
    }
  }

  Future<void> selectArrivalTime(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedArrivalTime ?? DateTime.now(),
      firstDate: _selectedDepartureTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedArrivalTime ?? DateTime.now(),
        ),
      );
      if (time != null) {
        _selectedArrivalTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        notifyListeners();
      }
    }
  }

  Future<void> updateFlight() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartureTime != null &&
        _selectedArrivalTime != null &&
        (_selectedArrivalTime!.isBefore(_selectedDepartureTime!) ||
            _selectedArrivalTime!.isAtSameMomentAs(_selectedDepartureTime!))) {
      _errorMessage = 'Arrival time must be after departure time';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final flightUpdate = FlightUpdate(
        departureTime: _selectedDepartureTime,
        arrivalTime: _selectedArrivalTime,
        status: _selectedStatus,
        gate: gateController.text.trim().isEmpty
            ? null
            : gateController.text.trim(),
        terminal: terminalController.text.trim().isEmpty
            ? null
            : terminalController.text.trim(),
        airplaneId: airplaneIdController.text.trim().isEmpty
            ? null
            : airplaneIdController.text.trim(),
      );

      await _flightService.updateFlight(
        flightIdController.text.trim(),
        flightUpdate,
      );

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight updated successfully')),
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

