import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.router.dart';
import '../../../app/app.locator.dart';
import '../../../services/flight_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/flight_model.dart';
import '../../../models/airport_model.dart';
import '../../../models/user_model.dart';
import '../admin_flights/admin_flights_view.dart';
import '../create_flight/create_flight_view.dart';
import '../admin_airplanes/admin_airplanes_view.dart';
import '../create_airplane/create_airplane_view.dart';
import '../admin_bookings/admin_bookings_view.dart';
import '../admin_payments/admin_payments_view.dart';
import '../delete_flight/delete_flight_view.dart';
import '../update_flight_status/update_flight_status_view.dart';
import '../update_gate_terminal/update_gate_terminal_view.dart';
import '../update_flight_simple/update_flight_simple_view.dart';

class FlightSearchViewModel extends BaseViewModel {
  final FlightService _flightService;
  final _authService = locator<AuthService>();
  final NavigationService _navigationService;

  UserPublic? _currentUser;
  UserPublic? get currentUser => _currentUser;
  bool get isStaff => _currentUser?.role == UserRole.staff;

  List<AirportPublic> _airports = [];
  List<AirportPublic> get airports => _airports;

  String? _selectedOriginId;
  String? get selectedOriginId => _selectedOriginId;

  String? _selectedDestinationId;
  String? get selectedDestinationId => _selectedDestinationId;

  DateTime? _selectedDateFrom;
  DateTime? get selectedDateFrom => _selectedDateFrom;

  DateTime? _selectedDateTo;
  DateTime? get selectedDateTo => _selectedDateTo;

  List<FlightSearchResult> _searchResults = [];
  List<FlightSearchResult> get searchResults => _searchResults;

  List<FlightPublic> _allFlights = [];
  List<FlightPublic> get allFlights => _allFlights;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  bool get canSearch =>
      _selectedOriginId != null &&
      _selectedDestinationId != null &&
      _selectedDateFrom != null;

  FlightSearchViewModel({
    FlightService? flightService,
    NavigationService? navigationService,
  })  : _flightService = flightService ?? FlightService(),
        _navigationService = navigationService ?? NavigationService();


  Future<void> loadUserData() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
      
      // If user is passenger, automatically load all flights
      if (_currentUser?.role == UserRole.passenger) {
        await loadAllFlights();
      }
    } catch (e) {
      // If user data fails, continue without it
      print('Failed to load user data: $e');
    }
  }

  Future<void> loadAllFlights() async {
    setBusy(true);
    _errorMessage = null;
    _allFlights = [];
    notifyListeners();

    try {
      _allFlights = await _flightService.getFlights(limit: 100);
      print('FlightSearchViewModel: Loaded ${_allFlights.length} flights for passenger');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('FlightSearchViewModel: Error loading flights: $e');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadAirports() async {
    setBusy(true);
    try {
      _airports = await _flightService.getAirports();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void setOrigin(String? value) {
    _selectedOriginId = value;
    notifyListeners();
  }

  void setDestination(String? value) {
    _selectedDestinationId = value;
    notifyListeners();
  }

  Future<void> selectDateFrom(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _selectedDateTo ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _selectedDateFrom = picked;
      // If end date is before start date, clear it
      if (_selectedDateTo != null && _selectedDateTo!.isBefore(picked)) {
        _selectedDateTo = null;
      }
      notifyListeners();
    }
  }

  Future<void> selectDateTo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTo ?? _selectedDateFrom ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _selectedDateFrom ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _selectedDateTo = picked;
      notifyListeners();
    }
  }

  Future<void> searchFlights() async {
    if (!canSearch) {
      print('FlightSearchViewModel: Cannot search - missing required fields');
      return;
    }

    print('FlightSearchViewModel: Starting flight search...');
    print('  - Origin: $_selectedOriginId');
    print('  - Destination: $_selectedDestinationId');
    print('  - Date From: $_selectedDateFrom');
    print('  - Date To: $_selectedDateTo');

    _errorMessage = null;
    _searchResults = [];
    notifyListeners();

    setBusy(true);

    try {
      _searchResults = await _flightService.searchFlights(
        originAirportId: _selectedOriginId!,
        destinationAirportId: _selectedDestinationId!,
        departureDateFrom: _selectedDateFrom!,
        departureDateTo: _selectedDateTo,
      );
      
      print('FlightSearchViewModel: Search completed. Found ${_searchResults.length} flights');
      
      if (_searchResults.isEmpty) {
        _errorMessage = 'No flights found for the selected criteria. Please try different dates or airports.';
        print('FlightSearchViewModel: No flights found');
      } else {
        print('FlightSearchViewModel: Displaying ${_searchResults.length} flights to user');
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      print('FlightSearchViewModel: Error during search - $e');
      print('FlightSearchViewModel: Stack trace - $stackTrace');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _searchResults = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void selectFlight(String flightId) {
    _navigationService.navigateTo(
      Routes.bookingView,
      arguments: BookingViewArguments(flightId: flightId),
    );
  }

  void navigateToBookings() {
    _navigationService.navigateTo(Routes.myBookingsView);
  }

  void navigateToProfile() {
    _navigationService.navigateTo(Routes.profileView);
  }

  void navigateToCreateFlight() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateFlightView()),
      );
    }
  }

  void navigateToFlightsList() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminFlightsView()),
      );
    }
  }

  void navigateToCreateAirplane() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateAirplaneView()),
      );
    }
  }

  void navigateToAirplanesList() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminAirplanesView()),
      );
    }
  }

  void navigateToBookingsList() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminBookingsView()),
      );
    }
  }

  void navigateToPaymentsList() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminPaymentsView()),
      );
    }
  }

  void navigateToUpdateFlight() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpdateFlightSimpleView()),
      );
    }
  }

  void navigateToDeleteFlight() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeleteFlightView()),
      );
    }
  }

  void navigateToUpdateFlightStatus() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpdateFlightStatusView()),
      );
    }
  }

  void navigateToUpdateGateTerminal() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpdateGateTerminalView()),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _navigationService.replaceWith(Routes.loginView);
  }
}

