import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class FlightDetailsViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();

  FlightPublic? _flight;
  FlightPublic? get flight => _flight;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  @override
  bool get hasError => _errorMessage != null;

  final String flightId;

  FlightDetailsViewModel({required this.flightId});

  Future<void> loadFlightDetails() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _flight = await _flightService.getFlight(flightId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}

