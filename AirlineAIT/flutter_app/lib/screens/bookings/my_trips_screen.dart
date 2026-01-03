import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/booking_card.dart';
import '../checkin/checkin_screen.dart';
import '../checkin/boarding_pass_screen.dart';
import '../flights/flight_details_screen.dart';
import '../payment/payment_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
    
    // Auto-refresh every 30 seconds while the screen is active
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadBookings(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getMyBookings();

      if (mounted) {
        setState(() {
          // Show all bookings (CONFIRMED, CANCELLED, etc.) so they can be classified
          _bookings = List<dynamic>.from(response.data);
          // Sort by departure time descending (newest first)
          _bookings.sort((a, b) {
             try {
               final dateA = _getDepartureTime(a);
               final dateB = _getDepartureTime(b);
               if (dateA == null && dateB == null) return 0;
               if (dateA == null) return 1;
               if (dateB == null) return -1;
               return dateB.compareTo(dateA); 
             } catch (e) {
               return 0;
             }
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading bookings: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load trips';
          _isLoading = false;
        });
      }
    }
  }

  DateTime? _getDepartureTime(dynamic booking) {
    try {
      final tickets = booking['tickets'] as List?;
      if (tickets == null || tickets.isEmpty) return null;
      final flight = tickets[0]['flight'];
      if (flight == null) return null;
      final dt = flight['departure_time'] as String?;
      if (dt == null) return null;
      return DateTime.parse(dt);
    } catch (_) {
      return null;
    }
  }

  // Helper to check if a booking's flight is in the past
  bool _isFlightPast(dynamic booking) {
    try {
      final tickets = booking['tickets'] as List?;
      if (tickets == null || tickets.isEmpty) return false;

      final flight = tickets[0]['flight'];
      if (flight == null) return false;
      
      // 1. Classification based on Flight Status
      final status = flight['status'] as String?;
      final bookingStatus = booking['status'] as String?;
      
      // If booking itself is CANCELLED, it belongs in Past (or separate Cancelled list, but for now Past)
      if (bookingStatus == 'CANCELLED') {
         print('DEBUG: Trip ${flight['flight_number']} is Past (Booking CANCELLED)');
         return true;
      }

      // If Flight is CANCELLED, DEPARTED, or LANDED -> Past
      if (status == 'DEPARTED' || status == 'LANDED' || status == 'CANCELLED') {
        print('DEBUG: Trip ${flight['flight_number']} is Past (Flight Status: $status)');
        return true;
      }
      
      // 2. Classification based on Time (Local)
      final departureStr = flight['departure_time'] as String?;
      if (departureStr == null) return false;
      
      final departureTime = DateTime.parse(departureStr);
      final now = DateTime.now();
      
      final isPast = departureTime.isBefore(now);
      print('DEBUG: Trip ${flight['flight_number']} time check: Flight $departureTime vs Now $now -> Past? $isPast');
      
      return isPast;
    } catch (e) {
      print('DEBUG: Error in _isFlightPast: $e');
      return false;
    }
  }

  List<dynamic> get _upcomingFlights {
    return _bookings.where((b) {
      final status = b['status'] as String?;
      // Only confirmed bookings that haven't departed yet
      return status == 'CONFIRMED' && !_isFlightPast(b);
    }).toList();
  }

  List<dynamic> get _pastFlights {
    return _bookings.where((b) {
      final status = b['status'] as String?;
      // Confirmed bookings that have departed, or cancelled bookings
      return (status == 'CONFIRMED' && _isFlightPast(b)) || status == 'CANCELLED';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadBookings,
      );
    }

    if (_bookings.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Trips Found',
        message: 'Your confirmed trips will appear here.',
        icon: Icons.flight_takeoff_outlined,
      );
    }

    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.flight_takeoff),
                text: 'Upcoming (${_upcomingFlights.length})',
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: 'Past (${_pastFlights.length})',
              ),
            ],
          ),
        ),
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Upcoming Flights Tab
              _buildFlightsList(_upcomingFlights, isUpcoming: true),
              // Past Flights Tab
              _buildFlightsList(_pastFlights, isUpcoming: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlightsList(List<dynamic> flights, {required bool isUpcoming}) {
    if (flights.isEmpty) {
      return EmptyStateWidget(
        title: isUpcoming ? 'No Upcoming Flights' : 'No Past Flights',
        message: isUpcoming 
            ? 'Your upcoming trips will appear here.'
            : 'Your past trips will appear here.',
        icon: isUpcoming ? Icons.flight_takeoff_outlined : Icons.history_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: flights.length,
        itemBuilder: (context, index) {
          final booking = flights[index];
          return BookingCard(
            booking: booking,
            onCancel: isUpcoming ? _showCancelDialog : null,
            onCheckIn: isUpcoming ? (ticketId) async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckInScreen(ticketId: ticketId),
                ),
              );
              _loadBookings();
            } : null,
            onViewBoardingPass: isUpcoming ? (ticketId) async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BoardingPassScreen(ticketId: ticketId),
                ),
              );
              _loadBookings();
            } : null,
            onRefresh: _loadBookings,
          );
        },
      ),
    );
  }

  Future<void> _showCancelDialog(int bookingId, String pnr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel booking $pnr?\n\n'
          'Note: Confirmed bookings cannot be cancelled once check-in opens (24 hours before departure).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelBooking(bookingId);
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.cancelBooking(bookingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to cancel booking';
        if (e.toString().contains('Check-in has started')) {
          errorMessage = 'Check-in has started. Confirmed bookings can no longer be cancelled.';
        } else if (e.toString().contains('already cancelled')) {
          errorMessage = 'Booking is already cancelled';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
