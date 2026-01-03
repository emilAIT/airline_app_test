import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/airplane_service.dart';
import '../../../models/airplane_model.dart';

class CreateAirplaneViewModel extends BaseViewModel {
  final AirplaneService _airplaneService = AirplaneService();
  final NavigationService _navigationService = locator<NavigationService>();

  final formKey = GlobalKey<FormState>();

  final modelController = TextEditingController();
  final rowsController = TextEditingController();
  final seatsPerRowController = TextEditingController();
  final extraLegroomRowsController = TextEditingController();

  List<SeatTemplateBase> _seatMap = [];
  List<SeatTemplateBase> get seatMap => _seatMap;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void generateSeatMap() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final rows = int.tryParse(rowsController.text);
    final seatsPerRow = seatsPerRowController.text.trim().toUpperCase();
    final extraLegroomRows = int.tryParse(extraLegroomRowsController.text) ?? 0;

    if (rows == null || rows <= 0) {
      _errorMessage = 'Number of rows must be greater than 0';
      notifyListeners();
      return;
    }

    if (seatsPerRow.isEmpty) {
      _errorMessage = 'Seats per row cannot be empty';
      notifyListeners();
      return;
    }

    _seatMap = [];
    for (int row = 1; row <= rows; row++) {
      for (int i = 0; i < seatsPerRow.length; i++) {
        final seatLabel = seatsPerRow[i];
        final category = row <= extraLegroomRows
            ? SeatCategory.extraLegroom
            : SeatCategory.standard;
        
        _seatMap.add(SeatTemplateBase(
          row: row,
          seatLabel: seatLabel,
          category: category,
        ));
      }
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> createAirplane() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_seatMap.isEmpty) {
      _errorMessage = 'Please generate seat map first';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final request = AirplaneCreateRequest(
        model: modelController.text.trim(),
        seatMap: _seatMap,
      );

      await _airplaneService.createAirplane(request);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airplane created successfully')),
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

