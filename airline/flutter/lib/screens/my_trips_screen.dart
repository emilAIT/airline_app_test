// SCREEN: MyTripsScreen
// PURPOSE: Display user's bookings organized by status (On Hold, Upcoming, Past/Expired)
// FEATURES: Live countdown timers for held bookings, automatic refresh on expiration

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_countdown_timer.dart';
import '../widgets/cancellation_dialog.dart';
import '../models/booking.dart';
import 'booking_detail_screen.dart';
import 'payment_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void didUpdateWidget(MyTripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _api.getMyBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  List<dynamic> get _onHoldBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      if (b['status'] != 'CREATED') return false;
      if (b['hold_until'] == null) return false;
      var dateStr = b['hold_until'];
      if (!dateStr.endsWith('Z')) dateStr += 'Z'; // Force UTC interpretation
      final holdUntil = DateTime.parse(dateStr);
      return holdUntil.isAfter(now);
    }).toList();
  }

  List<dynamic> get _upcomingBookings {
    return _bookings.where((b) => b['status'] == 'CONFIRMED').toList();
  }

  List<dynamic> get _pastBookings {
    return _bookings
        .where((b) => ['EXPIRED', 'COMPLETED', 'CANCELLED', 'REFUNDED'].contains(b['status']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: EldiyarTheme.darkerBackground,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBookings,
                child: _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flight_outlined,
                              size: 80,
                              color: EldiyarTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No bookings found',
                              style: TextStyle(
                                color: EldiyarTheme.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // On Hold Section
                            if (_onHoldBookings.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.timer_outlined,
                                title: 'On Hold (Awaiting Payment)',
                                color: EldiyarTheme.accentTeal,
                              ),
                              const SizedBox(height: 12),
                              ..._onHoldBookings.map((booking) =>
                                  _HoldBookingCard(
                                    booking: booking,
                                    onExpired: _loadBookings,
                                    onPaymentPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentScreen(
                                            bookingId: booking['id'],
                                          ),
                                        ),
                                      ).then((_) => _loadBookings());
                                    },
                                  )),
                              const SizedBox(height: 24),
                            ],

                            // Upcoming Trips Section
                            if (_upcomingBookings.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.flight_takeoff,
                                title: 'Upcoming Trips',
                                color: EldiyarTheme.primaryBlue,
                              ),
                              const SizedBox(height: 12),
                              ..._upcomingBookings.map((booking) =>
                                  _UpcomingBookingCard(
                                    booking: booking,
                                    onRefresh: _loadBookings,
                                  )),
                              const SizedBox(height: 24),
                            ],

                            // Past/Expired Section
                            if (_pastBookings.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.history,
                                title: 'Past / Expired',
                                color: EldiyarTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              ..._pastBookings.map((booking) =>
                                  _PastBookingCard(booking: booking)),
                            ],
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}

// Section header widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// On Hold booking card with countdown timer
class _HoldBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onExpired;
  final VoidCallback onPaymentPressed;

  const _HoldBookingCard({
    required this.booking,
    required this.onExpired,
    required this.onPaymentPressed,
  });

  @override
  Widget build(BuildContext context) {
    final flight = booking['flight'];
    final tickets = booking['tickets'] as List;
    var dateStr = booking['hold_until'];
    if (!dateStr.endsWith('Z')) dateStr += 'Z';
    final holdUntil = DateTime.parse(dateStr);
    final totalPrice = flight['base_price'] * tickets.length;
    final isExpired = DateTime.now().isAfter(holdUntil);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: EldiyarTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: EldiyarTheme.accentTeal.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  flight['flight_number'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: EldiyarTheme.primaryBlue,
                  ),
                ),
                BookingCountdownTimer(
                  holdUntil: holdUntil,
                  onExpired: onExpired,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${flight['origin']['code']} → ${flight['destination']['code']}',
              style: const TextStyle(fontSize: 16, color: EldiyarTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Seats: ${tickets.map((t) => t['seat_number']).join(', ')}',
              style: const TextStyle(color: EldiyarTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: \$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: EldiyarTheme.accentTeal,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isExpired ? null : onPaymentPressed,
                icon: Icon(isExpired ? Icons.block : Icons.payment),
                label: Text(isExpired ? 'Expired' : 'Continue Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired 
                      ? EldiyarTheme.errorRed.withOpacity(0.5)
                      : EldiyarTheme.accentTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: EldiyarTheme.errorRed.withOpacity(0.3),
                  disabledForegroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Upcoming booking card
class _UpcomingBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;

  const _UpcomingBookingCard({
    required this.booking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final flight = booking['flight'];
    final tickets = booking['tickets'] as List;
    final departureTime = DateTime.parse(flight['departure_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: EldiyarTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EldiyarTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flight_takeoff, color: EldiyarTheme.primaryBlue),
            ),
            title: Text(
              flight['flight_number'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${flight['origin']['code']} → ${flight['destination']['code']}'),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(departureTime)),
                Text('Seats: ${tickets.map((t) => t['seat_number']).join(', ')}'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(bookingId: booking['id']),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CancellationDialog(
                          booking: Booking.fromJson(booking),
                          onCancelled: onRefresh,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, color: EldiyarTheme.errorRed),
                    label: const Text('Cancel Booking', style: TextStyle(color: EldiyarTheme.errorRed)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EldiyarTheme.errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Past/expired booking card
class _PastBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _PastBookingCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
      case 'CONFIRMED':
        return EldiyarTheme.successGreen;
      case 'Refunded':
      case 'REFUNDED':
        return Colors.orange;
      case 'Expired':
      case 'EXPIRED':
      case 'Cancelled':
      case 'CANCELLED':
        return EldiyarTheme.errorRed;
      default:
        return EldiyarTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flight = booking['flight'];
    final status = booking['status'];
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: EldiyarTheme.cardBackground.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: EldiyarTheme.textSecondary.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          status == 'EXPIRED' ? Icons.schedule : Icons.history,
          color: statusColor,
        ),
        title: Text(
          flight['flight_number'],
          style: TextStyle(color: statusColor),
        ),
        subtitle: Text(
          '${flight['origin']['code']} → ${flight['destination']['code']}',
          style: const TextStyle(color: EldiyarTheme.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
