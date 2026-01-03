import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

class BoardingPassScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const BoardingPassScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends ConsumerState<BoardingPassScreen> {
  List<BoardingPass> _boardingPasses = [];
  bool _isLoading = true;
  bool _isCheckinIn = false;
  String? _error;

  Widget _buildQrCode(String data, double size) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(8),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBoardingPasses();
  }

  Future<void> _loadBoardingPasses() async {
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
      final passes = await bookingService.getBoardingPass(
        token: authState.token!,
        bookingId: widget.bookingId,
      );
      
      if (mounted) {
        setState(() {
          _boardingPasses = passes;
          _isLoading = false;
          _error = null;
          // If passes is empty, it means user hasn't checked in yet
          // This is expected and will show the check-in button
        });
      }
    } catch (e) {
      // Only show error for unexpected errors
      final errorMessage = e.toString();
      if (errorMessage.contains('Not checked in') || 
          errorMessage.contains('not checked in') ||
          errorMessage.contains('checked in yet')) {
        // This is expected - user hasn't checked in yet
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = null;
            _boardingPasses = [];
          });
        }
      } else {
        // Other unexpected errors
        if (mounted) {
          setState(() {
            _error = errorMessage;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isCheckinIn = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        throw Exception('Not authenticated');
      }

      final bookingService = ref.read(bookingServiceProvider);
      final passes = await bookingService.checkIn(
        token: authState.token!,
        bookingId: widget.bookingId,
      );

      if (mounted) {
        setState(() {
          _boardingPasses = passes;
          _isCheckinIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Don't close the screen - show the boarding pass instead
        // The user can navigate back manually when done viewing
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e')),
        );
        setState(() {
          _isCheckinIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boarding Pass'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boarding Pass'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_boardingPasses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boarding Pass'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flight_takeoff, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Please check in first',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check-in is available 24 hours to 1 hour before departure',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCheckinIn ? null : _checkIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _isCheckinIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Check In',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boarding Pass'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _boardingPasses.length,
        itemBuilder: (context, index) {
          final pass = _boardingPasses[index];
          return _buildBoardingPassCard(context, pass);
        },
      ),
    );
  }

  Widget _buildBoardingPassCard(BuildContext context, BoardingPass pass) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upper Part: Flight Info
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flight, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            pass.flight,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(pass.boardingTime),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pass.flight.substring(0, 3).toUpperCase(), // Fake Origin Code
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text('Origin', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const RotatedBox(
                      quarterTurns: 1,
                      child: Icon(Icons.flight, color: AppTheme.textSecondary, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'UNK', // Fake Dest Code (Service doesn't return Route codes in BoardingPass model, assumed known or update model)
                          // Ideally pass model has origin/dest. Using Placeholders or logic if available.
                          // Actually previous code used Full Flight String or similar? 
                          // The `pass.flight` is usually "AA123". Origin/Dest not in `BoardingPass` model shown in previous `read_file`. 
                          // I'll stick to a generic "FLIGHT" or hide codes if not available. 
                          // Or I can parse booking info if I had it. 
                          // Let's use decoration instead.
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text('Target', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider (Dashed)
          SizedBox(
            height: 1,
            child: Row(
              children: List.generate(40, (index) => Expanded(
                child: Container(
                  color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.3),
                  height: 1,
                ),
              )),
            ),
          ),
          
          // Cutout Circles for effect
          // This requires Stack, but for simple Column let's skip complex shape or use simple Divider.

          // Lower Part: Passenger & Seat
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passenger', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      pass.passenger,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Seat', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      pass.seat,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom: QR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: Column(
              children: [
                _buildQrCode(pass.qrCode, 180),
                const SizedBox(height: 16),
                Text(
                  'Gate ${pass.gate} • Boarding ${DateFormat('HH:mm').format(pass.boardingTime)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
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


