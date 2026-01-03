import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.locator.dart';
import '../../../services/booking_service.dart';
import '../../../services/flight_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/flight_model.dart';

class AdminBookingsViewModel extends BaseViewModel {
  final BookingService _bookingService = BookingService();
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  List<BookingPublic> _bookings = [];
  List<BookingPublic> get bookings => _bookings;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadBookings() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the new endpoint to get all bookings directly
      _bookings = await _bookingService.getAllBookings(limit: 200);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _bookings = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void viewBookingDetails(BuildContext context, BookingPublic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details - ${booking.pnr}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('PNR', booking.pnr),
              _buildDetailRow('Status', booking.status.name.toUpperCase()),
              _buildDetailRow('Flight ID', booking.flightId),
              _buildDetailRow('Booking ID', booking.id),
              _buildDetailRow(
                'Created',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(booking.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void showCancelDialog(BuildContext context, BookingPublic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel booking ${booking.pnr}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await cancelBooking(context, booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> cancelBooking(BuildContext context, BookingPublic booking) async {
    setBusy(true);
    try {
      await _bookingService.cancelBooking(booking.id);
      await loadBookings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }
}
