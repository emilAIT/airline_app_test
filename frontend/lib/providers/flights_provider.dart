import 'package:flutter/material.dart';
import '../models/flight.dart';
import '../core/api/flights_api.dart';

class FlightsProvider extends ChangeNotifier {
  final FlightsApi _api = FlightsApi();

  bool isLoading = false;
  String? error;
  List<Flight> flights = [];

  Future<void> load({
    required String origin,
    required String destination,
    required DateTime? departureDate,
  }) async {
    if (departureDate == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      flights = await _api.searchFlights(
        origin: origin,
        destination: destination,
        date: departureDate,
      );
    } catch (e) {
      // error = 'Flights not found';
      error = e.toString();
      flights = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      flights = await _api.getAllFlights();
    } catch (e) {
      error = e.toString();
      flights = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
