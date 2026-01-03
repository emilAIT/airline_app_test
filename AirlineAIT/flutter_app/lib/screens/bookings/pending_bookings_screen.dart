import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/booking_card.dart';
import 'my_trips_screen.dart';
import '../home/home_screen.dart'; // To redirect to Home for refresh

class PendingBookingsScreen extends StatefulWidget {
  const PendingBookingsScreen({super.key});

  @override
  State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getMyBookings();

      if (mounted) {
        setState(() {
          // Filter HOLD and EXPIRED bookings
          _bookings = (response.data as List)
              .where((b) => b['status'] == 'HOLD' || b['status'] == 'EXPIRED')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load pending bookings';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();

    if (_errorMessage != null) {
      return ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadBookings);
    }

    if (_bookings.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Pending Bookings',
        message: 'You have no bookings waiting for payment.',
        icon: Icons.payments_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return BookingCard(
            booking: booking,
            onCancel: (id, pnr) async {
               // Reuse cancellation logic from my_trips_screen if possible or implement here
               await _cancelBooking(id);
            },
            onCheckIn: (_) {}, // Not applicable for HOLD
            onRefresh: _loadBookings,
          );
        },
      ),
    );
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: Colors.green),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
