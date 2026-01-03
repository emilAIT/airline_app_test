import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'boarding_pass_screen.dart';
import 'payment_screen.dart';
import 'package:dio/dio.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String? _error;
  Timer? _paymentTimer;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _paymentTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final bookingService = ref.read(bookingServiceProvider);
      final booking = await bookingService.getBookingDetails(
        token: authState.token!,
        bookingId: widget.bookingId,
      );

      if (mounted) {
        if (booking.isPending) {
          final remainingTime = _calculateRemainingTime(booking.createdAt);
          if (remainingTime.isNegative || remainingTime.inSeconds <= 0) {
            await Future.delayed(const Duration(milliseconds: 100));
            final updatedBooking = await bookingService.getBookingDetails(
              token: authState.token!,
              bookingId: widget.bookingId,
            );
            setState(() {
              _booking = updatedBooking;
              _isLoading = false;
            });
            return;
          }
        }
        
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
        
        if (booking.isPending) {
          _startPaymentTimer();
        }
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

  Duration _calculateRemainingTime(DateTime createdAt) {
    try {
      final createdAtUtc = createdAt.isUtc ? createdAt : createdAt.toUtc();
      final expiryTime = createdAtUtc.add(const Duration(minutes: 10));
      final nowUtc = DateTime.now().toUtc();
      return expiryTime.difference(nowUtc);
    } catch (e) {
      return const Duration(seconds: 0);
    }
  }

  void _startPaymentTimer() {
    _paymentTimer?.cancel();
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _booking == null || !_booking!.isPending) {
        timer.cancel();
        return;
      }
      
      final remaining = _getRemainingPaymentTime();
      
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        await _loadBooking();
      } else {
        setState(() {}); // Trigger rebuild
      }
    });
  }

  Duration _getRemainingPaymentTime() {
    if (_booking == null || !_booking!.isPending) {
      return const Duration(seconds: 0);
    }
    
    final remaining = _calculateRemainingTime(_booking!.createdAt);
    
    if (remaining.inSeconds > 600) {
      return const Duration(minutes: 10);
    }
    
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return const Duration(seconds: 0);
    }
    
    return remaining;
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative || duration.inSeconds <= 0) {
      return '00:00';
    }
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _booking == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBooking,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final booking = _booking!;
    final flight = booking.flight;

    if (flight == null) {
      return const Center(child: Text('Flight information not available', style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status and PNR
          _buildInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PNR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text(
                          booking.pnr,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(booking.status).withOpacity(0.5)),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Flight Details
          _buildInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.plane, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Flight ${flight.flightNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF334155), height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(flight.departureAirportCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(DateFormat('HH:mm').format(flight.departureTime), style: const TextStyle(color: Colors.white, fontSize: 18)),
                        Text(DateFormat('MMM dd').format(flight.departureTime), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                    const Icon(LucideIcons.moveRight, color: AppTheme.textSecondary),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(flight.arrivalAirportCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(DateFormat('HH:mm').format(flight.arrivalTime), style: const TextStyle(color: Colors.white, fontSize: 18)),
                        Text(DateFormat('MMM dd').format(flight.arrivalTime), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                if (flight.gate != null) ...[
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       const Icon(LucideIcons.doorOpen, color: AppTheme.textSecondary, size: 16),
                       const SizedBox(width: 8),
                       Text('Gate ${flight.gate}', style: const TextStyle(color: AppTheme.textSecondary)),
                     ],
                   ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          
          // Passengers
          _buildInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.users, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Passengers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...booking.tickets.map((ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.passengerName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Ticket: ${ticket.ticketNumber}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.armchair, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              ticket.seatNumber,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timer & Actions
          if (booking.isPending) ...[
             Builder(
                builder: (context) {
                  final remainingTime = _getRemainingPaymentTime();
                  final isExpired = remainingTime.isNegative || remainingTime.inSeconds <= 0;
                  
                  if (isExpired && _paymentTimer != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
                  }
                  
                  if (isExpired) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle, color: AppTheme.errorColor, size: 20),
                          SizedBox(width: 8),
                          Text('Expired', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  
                  // Modern Timer Style
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFF59E0B).withOpacity(0.2), const Color(0xFFF59E0B).withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Payment Time Remaining',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatRemainingTime(remainingTime),
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Pay Button - Modern Gradient
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)], // Green gradient
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                bookingId: booking.id,
                                amount: booking.totalPrice,
                              ),
                            ),
                          ).then((_) {
                            _loadBooking();
                          });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.creditCard, size: 22, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Pay \$${booking.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          if (booking.isConfirmed) ...[
            Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF334155), // Slate 700 for updated look
                ),
                child: ElevatedButton(
                onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BoardingPassScreen(bookingId: booking.id),
                      ),
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.qrCode, size: 22),
                    SizedBox(width: 12),
                    Text('View Boarding Pass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'CANCELLED': return AppTheme.errorColor;
      default: return AppTheme.textSecondary;
    }
  }
}
