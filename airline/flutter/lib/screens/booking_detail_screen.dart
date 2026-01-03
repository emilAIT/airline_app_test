import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'checkin_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _api.getBooking(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.cancelBooking(widget.bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling booking: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return const Scaffold(
        body: Center(child: Text('Booking not found')),
      );
    }

    final flight = _booking!['flight'];
    final tickets = _booking!['tickets'] as List;
    final departureTime = DateTime.parse(flight['departure_time']);

    return Scaffold(
      appBar: AppBar(title: Text('Booking ${_booking!['pnr']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['flight_number'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${flight['origin']['code']} → ${flight['destination']['code']}',
                    ),
                    const SizedBox(height: 8),
                    Text('Departure: ${DateFormat('MMM dd, yyyy HH:mm').format(departureTime)}'),
                    Text('Status: ${_booking!['status']}'),
                    if (_booking!['payment'] != null) ...[
                      const Divider(),
                      Text('Payment: ${_booking!['payment']['status']}'),
                      Text('Method: ${_booking!['payment']['method']}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tickets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...tickets.map((ticket) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(ticket['passenger_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seat: ${ticket['seat_number']}'),
                      Text('Ticket: ${ticket['ticket_number']}'),
                    ],
                  ),
                  trailing: _booking!['status'] == 'CONFIRMED'
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckInScreen(
                                  ticketId: ticket['id'],
                                ),
                              ),
                            );
                          },
                          child: const Text('Check In'),
                        )
                      : null,
                ),
              );
            }),
            if (_booking!['status'] != 'CANCELLED' &&
                _booking!['status'] != 'CONFIRMED')
              ElevatedButton(
                onPressed: _cancelBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel Booking'),
              ),
          ],
        ),
      ),
    );
  }
}

