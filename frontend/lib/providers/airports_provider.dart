import 'package:flutter/material.dart';
import '../models/airport.dart';
import '../core/api/airports_api.dart';

class AirportsProvider extends ChangeNotifier {
  final AirportsApi _api = AirportsApi();

  bool isLoading = false;
  String? error;
  List<Airport> airports = [];

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      airports = await _api.getAllAirports();
    } catch (e) {
      error = e.toString();
      airports = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
