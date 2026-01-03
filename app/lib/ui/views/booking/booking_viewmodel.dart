import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/airport_service.dart';
import '../../../models/flight_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/seat_model.dart';
import '../../../models/airport_model.dart';

class PassengerData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passportController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  String? selectedSeatId;
  DateTime? dateOfBirth;

  void dispose() {
    nameController.dispose();
    passportController.dispose();
    nationalityController.dispose();
    dateOfBirthController.dispose();
  }

  bool get isValid =>
      nameController.text.trim().isNotEmpty &&
      passportController.text.trim().isNotEmpty &&
      nationalityController.text.trim().isNotEmpty &&
      dateOfBirth != null;
}

class BookingViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final BookingService _bookingService = locator<BookingService>();
  final AirportService _airportService = locator<AirportService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final String flightId;
  FlightPublic? _flight;
  FlightPublic? get flight => _flight;

  AirportPublic? _originAirport;
  AirportPublic? get originAirport => _originAirport;

  AirportPublic? _destinationAirport;
  AirportPublic? get destinationAirport => _destinationAirport;

  SeatMapResponse? _seatMap;
  SeatMapResponse? get seatMap => _seatMap;

  final List<PassengerData> _passengers = [PassengerData()];
  List<PassengerData> get passengers => _passengers;

  bool _autoAssignSeats = false;
  bool get autoAssignSeats => _autoAssignSeats;
  set autoAssignSeats(bool value) {
    _autoAssignSeats = value;
    if (value) {
      // Clear all selected seats when auto-assign is enabled
      for (var passenger in _passengers) {
        passenger.selectedSeatId = null;
      }
    }
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  bool get canCreateBooking {
    if (_flight == null) return false;
    if (_flight!.status == FlightStatus.cancelled || 
        _flight!.status == FlightStatus.departed) {
      return false;
    }
    if (_passengers.isEmpty) return false;
    if (!_autoAssignSeats) {
      // If manual seat selection, all passengers must have seats
      if (_passengers.length != _passengers.where((p) => p.selectedSeatId != null).length) {
        return false;
      }
    }
    return _passengers.every((p) => p.isValid);
  }

  BookingViewModel({
    required this.flightId,
  });

  Future<void> loadFlightData() async {
    print('BookingViewModel: Starting to load flight data for flightId: $flightId');
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Load flight details
      print('BookingViewModel: Loading flight details...');
      _flight = await _flightService.getFlight(flightId);
      print('BookingViewModel: Flight loaded: ${_flight?.flightNumber}');
      
      // Load airports (non-blocking - if they fail, we still show the flight)
      if (_flight != null) {
        try {
          print('BookingViewModel: Loading origin airport: ${_flight!.originAirportId}');
          _originAirport = await _airportService.getAirport(_flight!.originAirportId);
          print('BookingViewModel: Origin airport loaded: ${_originAirport?.name}');
        } catch (e) {
          print('BookingViewModel: Error loading origin airport: $e');
          // Don't set error, just continue without airport name
        }
        try {
          print('BookingViewModel: Loading destination airport: ${_flight!.destinationAirportId}');
          _destinationAirport = await _airportService.getAirport(_flight!.destinationAirportId);
          print('BookingViewModel: Destination airport loaded: ${_destinationAirport?.name}');
        } catch (e) {
          print('BookingViewModel: Error loading destination airport: $e');
          // Don't set error, just continue without airport name
        }
      }

      // Load seat map (non-blocking - if it fails, we still show the form)
      try {
        print('BookingViewModel: Loading seat map...');
        _seatMap = await _flightService.getSeatMap(flightId);
        print('BookingViewModel: Seat map loaded: ${_seatMap?.seats.length} seats');
      } catch (e) {
        print('BookingViewModel: Error loading seat map: $e');
        // Don't set error as critical - seat map is optional for booking
        // User can still create booking without seat map
      }

      print('BookingViewModel: Data loading completed successfully');
      notifyListeners();
    } catch (e) {
      print('BookingViewModel: Error loading flight data: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
      print('BookingViewModel: Loading finished, isBusy: false');
    }
  }

  void addPassenger() {
    _passengers.add(PassengerData());
    notifyListeners();
  }

  void removePassenger(int index) {
    if (_passengers.length > 1) {
      _passengers[index].dispose();
      _passengers.removeAt(index);
      notifyListeners();
    }
  }

  void selectSeatForPassenger(int passengerIndex, String? seatId) {
    if (passengerIndex >= 0 && passengerIndex < _passengers.length) {
      _passengers[passengerIndex].selectedSeatId = seatId;
      notifyListeners();
    }
  }

  Future<void> selectDateOfBirth(BuildContext context, int passengerIndex) async {
    final passenger = _passengers[passengerIndex];
    final initialDate = passenger.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      passenger.dateOfBirth = picked;
      passenger.dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      notifyListeners();
    }
  }

  Future<void> createBooking() async {
    if (!canCreateBooking) return;

    _errorMessage = null;
    notifyListeners();

    setBusy(true);

    try {
      final booking = BookingCreate(
        flightId: flightId,
        passengers: _passengers.map((p) {
          return BookingPassenger(
            passengerName: p.nameController.text.trim(),
            seatId: _autoAssignSeats ? null : p.selectedSeatId,
          );
        }).toList(),
      );

      final createdBooking = await _bookingService.createBooking(booking);
      
      // Navigate to payment page
      _navigationService.navigateTo(
        Routes.paymentView,
        arguments: PaymentViewArguments(bookingId: createdBooking.id),
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    for (var passenger in _passengers) {
      passenger.dispose();
    }
    super.dispose();
  }
}
