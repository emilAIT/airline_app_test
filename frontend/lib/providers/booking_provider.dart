import 'package:flutter/material.dart';
import '../core/api/bookings_api.dart';
import '../models/booking.dart';
import '../models/ticket.dart';
import '../models/seat.dart';

class BookingProvider extends ChangeNotifier {
  Booking? booking;
  Ticket? boardingPass;
  List<Seat> seats = [];
  List<Booking> userBookings = [];
  bool loading = false;
  String? error;

  Future<void> fetchSeatMap(int flightId) async {
    loading = true;
    error = null;
    notifyListeners();

    seats = await BookingsApi.getSeatMap(flightId);

    loading = false;
    notifyListeners();
  }

  Future<bool> holdSeats(int flightId, List<String> selectedSeats) async {
    loading = true;
    error = null;
    notifyListeners();

    final success = await BookingsApi.holdSeats(flightId, selectedSeats);
    
    if (!success) {
      error = "Failed to hold seats. They might be already taken.";
    }

    loading = false;
    notifyListeners();
    return success;
  }

  Future<void> create(
    int flightId,
    List<String> selectedSeats,
  ) async {
    loading = true;
    error = null;
    notifyListeners();

    booking = await BookingsApi.createBooking(flightId, selectedSeats);
    
    if (booking == null) {
      error = "Booking failed. Make sure your profile is complete.";
    }

    loading = false;
    notifyListeners();
  }

  Future<void> checkIn(int ticketId) async {
    boardingPass = await BookingsApi.checkIn(ticketId);
    notifyListeners();
  }

  Future<void> fetchUserBookings() async {
    loading = true;
    notifyListeners();
    try {
      userBookings = await BookingsApi.getUserBookings();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}