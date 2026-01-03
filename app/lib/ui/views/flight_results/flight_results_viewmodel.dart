import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';

class FlightResultsViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  List<FlightSearchResult> _flights = [];
  List<FlightSearchResult> get flights => _flights;

  FlightSearchParams? _searchParams;
  FlightSearchParams? get searchParams => _searchParams;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  @override
  bool get hasError => _errorMessage != null;

  bool get isEmpty => !isBusy && _flights.isEmpty && !hasError;

  FlightResultsViewModel({
    List<FlightSearchResult>? initialFlights,
    FlightSearchParams? searchParams,
  }) {
    if (initialFlights != null) {
      _flights = initialFlights;
    }
    _searchParams = searchParams;
  }

  Future<void> loadFlights() async {
    if (_searchParams == null) {
      _errorMessage = 'Search parameters not provided';
      notifyListeners();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _flights = await _flightService.searchFlights(
        originAirportId: _searchParams!.originAirportId,
        destinationAirportId: _searchParams!.destinationAirportId,
        departureDateFrom: _searchParams!.departureDateFrom,
        departureDateTo: _searchParams!.departureDateTo,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> refreshFlights() async {
    await loadFlights();
  }

  void navigateToFlightDetails(String flightId) {
    _navigationService.navigateTo(
      Routes.flightDetailsView,
      arguments: FlightDetailsViewArguments(flightId: flightId),
    );
  }

  void navigateToBooking(String flightId) {
    _navigationService.navigateTo(
      Routes.bookingView,
      arguments: BookingViewArguments(flightId: flightId),
    );
  }
}

