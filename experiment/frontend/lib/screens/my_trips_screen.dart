import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'booking_details_screen.dart';
import 'boarding_pass_screen.dart';
import 'passenger_main_screen.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

class MyTripsScreen extends ConsumerStatefulWidget {
  const MyTripsScreen({super.key});

  @override
  ConsumerState<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends ConsumerState<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
    _startRefreshTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bookings when screen becomes visible again (but not too frequently)
    final now = DateTime.now();
    if (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 2) {
      _loadBookings();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final hasPending = _upcomingBookings.any((b) => b.isPending);
        if (hasPending) {
          setState(() {}); 
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadBookings() async {
    _lastLoadTime = DateTime.now();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingService = ref.read(bookingServiceProvider);
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }
      final bookings = await bookingService.getMyBookings(token: authState.token!);
      
      final now = DateTime.now();
      final upcoming = <Booking>[];
      final past = <Booking>[];

      for (var booking in bookings) {
        if (booking.isPending) {
          upcoming.add(booking);
        } else if (booking.flight?.departureTime != null) {
          if (booking.flight!.departureTime.isAfter(now)) {
            upcoming.add(booking);
          } else {
            past.add(booking);
          }
        }
      }

      setState(() {
        _upcomingBookings = upcoming;
        _pastBookings = past;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCancellation(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authState = ref.read(authProvider);
        if (authState.token == null) {
          throw Exception('Not authenticated');
        }

        final bookingService = ref.read(bookingServiceProvider);
        await bookingService.cancelBooking(
          token: authState.token!,
          bookingId: bookingId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBookings();
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,


        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
               ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(_upcomingBookings),
                    _buildBookingsList(_pastBookings),
                  ],
                ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plane, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              'No trips found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final flight = booking.flight;
    if (flight == null) return const SizedBox.shrink();

    Color statusColor;
    String statusText;
    
    switch (booking.status.toUpperCase()) {
      case 'CONFIRMED':
        statusColor = AppTheme.successColor;
        statusText = 'Booked';
        break;
      case 'PENDING':
        statusColor = AppTheme.warningColor;
        statusText = 'Pending Payment';
        break;
      case 'CANCELLED':
        statusColor = AppTheme.errorColor;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusText = booking.status;
    }
    
    // Check if Paid (Confirmed usually means paid or seat held depending on logic, but let's assume Confirmed = Paid)
    // Actually user says "Status: Booked, Paid, Completed"
    // Completed if past date.
    if (DateTime.now().isAfter(flight.arrivalTime)) {
      statusText = 'Completed';
      statusColor = AppTheme.textSecondary;
    } else if (booking.status == 'CONFIRMED') {
      statusText = 'Paid'; // Mapping Confirmed to Paid as per request
    }

    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Route + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        flight.departureAirportCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(LucideIcons.moveRight, color: AppTheme.textSecondary, size: 16),
                      ),
                      Text(
                        flight.arrivalAirportCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(flight.departureTime),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(LucideIcons.clock, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(flight.departureTime),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // View Ticket Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(bookingId: booking.id),
                    ),
                  ).then((_) {
                    _loadBookings(); // Refresh on return
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Ticket'),
              ),
            ),
            
            // View Boarding Ticket Button (only for paid/confirmed bookings)
            if (booking.isConfirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BoardingPassScreen(bookingId: booking.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.qrCode, size: 18),
                      SizedBox(width: 8),
                      Text('View Boarding Ticket'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

