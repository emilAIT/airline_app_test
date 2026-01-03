import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:dio/dio.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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

      final allBookings = await bookingService.getMyBookings(token: authState.token!);
      
      // Filter only CONFIRMED bookings for history (or any paid ones)
      // As per request "purchase history" implies bought items.
      final purchased = allBookings.where((b) => b.isConfirmed).toList();
      
      // Sort by date descending (newest first)
      purchased.sort((a, b) {
        final dateA = a.flight?.departureTime ?? DateTime.now();
        final dateB = b.flight?.departureTime ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _bookings = purchased;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Purchase History'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)))
              : _bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shoppingBag, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          const Text(
                            'No purchases yet',
                            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_bookings[index]);
                      },
                    ),
    );
  }

  Widget _buildHistoryCard(Booking booking) {
    final flight = booking.flight;
    if (flight == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Flight Number & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.plane, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    flight.flightNumber, // e.g. "AA123"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showFlightDetails(booking),
                child: Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor, // Green/Primary for money
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Row 2: Route (Origin -> Dest)
          Row(
            children: [
              Text(
                flight.departureAirportCode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.arrowRight, size: 16, color: AppTheme.textSecondary),
              ),
              Text(
                flight.arrivalAirportCode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
            // Row 3: Purchase Date
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Purchased: ${DateFormat('MMM d, yyyy • HH:mm').format(booking.createdAt.toLocal())}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          // Status intentionally omitted
        ],
      ),
    );
  }

  void _showFlightDetails(Booking booking) {
    final flight = booking.flight;
    if (flight == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Flight Details - ${flight.flightNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Route
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        flight.departureAirportCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(flight.departureTime),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.departureTime),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.flight, color: AppTheme.primaryColor),
                  ),
                  Column(
                    children: [
                      Text(
                        flight.arrivalAirportCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(flight.arrivalTime),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.arrivalTime),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Flight Duration
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${flight.duration.inHours}h ${flight.duration.inMinutes.remainder(60)}m',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Gate
              if (flight.gate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.door_front_door, size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Gate: ${flight.gate}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Terminal
              if (flight.terminal != null) ...[
                Row(
                  children: [
                    const Icon(Icons.business, size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Terminal: ${flight.terminal}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Status
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${flight.status}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Booking Info
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 12),
              const Text(
                'Booking Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PNR:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    booking.pnr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Price:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '\$${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Passengers:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '${booking.tickets.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Passengers List
              if (booking.tickets.isNotEmpty) ...[
                const Text(
                  'Passengers:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...booking.tickets.map((ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.passengerName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        'Seat: ${ticket.seatNumber}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
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
}
