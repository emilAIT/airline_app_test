import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/booking_service.dart';
import '../../../services/flight_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/flight_model.dart';
import '../../../models/airport_model.dart';

class BookingWithFlight {
  final BookingPublic booking;
  final FlightPublic? flight;
  final AirportPublic? originAirport;
  final AirportPublic? destinationAirport;

  BookingWithFlight({
    required this.booking,
    this.flight,
    this.originAirport,
    this.destinationAirport,
  });
}

class ManageTripsViewModel extends BaseViewModel {
  final BookingService _bookingService = locator<BookingService>();
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  List<BookingWithFlight> _upcomingBookings = [];
  List<BookingWithFlight> get upcomingBookings => _upcomingBookings;

  List<BookingWithFlight> _pastBookings = [];
  List<BookingWithFlight> get pastBookings => _pastBookings;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasUpcomingError => _errorMessage != null && _currentTabIndex == 0;
  bool get hasPastError => _errorMessage != null && _currentTabIndex == 1;

  ManageTripsViewModel();

  void setTabIndex(int index) {
    _currentTabIndex = index;
    _errorMessage = null;
    notifyListeners();
    if (index == 0 && _upcomingBookings.isEmpty) {
      loadUpcomingBookings();
    } else if (index == 1 && _pastBookings.isEmpty) {
      loadPastBookings();
    }
  }

  Future<void> loadUpcomingBookings() async {
    setBusy(true);
    _errorMessage = null;
    try {
      final bookings = await _bookingService.getMyBookings(scope: 'upcoming');
      _upcomingBookings = await _enrichBookingsWithFlightData(bookings);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _upcomingBookings = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadPastBookings() async {
    setBusy(true);
    _errorMessage = null;
    try {
      final bookings = await _bookingService.getMyBookings(scope: 'past');
      _pastBookings = await _enrichBookingsWithFlightData(bookings);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _pastBookings = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<List<BookingWithFlight>> _enrichBookingsWithFlightData(
      List<BookingPublic> bookings) async {
    final enriched = <BookingWithFlight>[];

    for (final booking in bookings) {
      FlightPublic? flight;
      AirportPublic? originAirport;
      AirportPublic? destinationAirport;

      try {
        flight = await _flightService.getFlight(booking.flightId);
        
        // Try to get airport information
        if (flight != null) {
          try {
            final airports = await _flightService.getAirports();
            if (airports.isNotEmpty) {
              originAirport = airports.firstWhere(
                (a) => a.id == flight!.originAirportId,
                orElse: () => airports.first,
              );
              destinationAirport = airports.firstWhere(
                (a) => a.id == flight!.destinationAirportId,
                orElse: () => airports.first,
              );
            }
          } catch (e) {
            // If airports fail, continue without them
            print('Failed to load airports: $e');
          }
        }
      } catch (e) {
        // If flight fails, continue without it
        print('Failed to load flight ${booking.flightId}: $e');
      }

      enriched.add(BookingWithFlight(
        booking: booking,
        flight: flight,
        originAirport: originAirport,
        destinationAirport: destinationAirport,
      ));
    }

    return enriched;
  }

  Future<void> refresh() async {
    if (_currentTabIndex == 0) {
      await loadUpcomingBookings();
    } else {
      await loadPastBookings();
    }
  }

  void viewBookingDetails(String bookingId) {
    _navigationService.navigateTo(
      Routes.bookingDetailsView,
      arguments: BookingDetailsViewArguments(bookingId: bookingId),
    );
  }

  String getRoute(BookingWithFlight bookingWithFlight) {
    if (bookingWithFlight.originAirport != null &&
        bookingWithFlight.destinationAirport != null) {
      return '${bookingWithFlight.originAirport!.code} → ${bookingWithFlight.destinationAirport!.code}';
    } else if (bookingWithFlight.flight != null) {
      return bookingWithFlight.flight!.flightNumber;
    }
    return 'N/A';
  }

  String getRouteFull(BookingWithFlight bookingWithFlight) {
    if (bookingWithFlight.originAirport != null &&
        bookingWithFlight.destinationAirport != null) {
      return '${bookingWithFlight.originAirport!.city} → ${bookingWithFlight.destinationAirport!.city}';
    }
    return getRoute(bookingWithFlight);
  }
}

