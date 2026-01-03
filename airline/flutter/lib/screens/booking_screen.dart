import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';

class BookingScreen extends StatefulWidget {
  final int flightId;
  final Map<String, dynamic> flight;
  final List<String> selectedSeats;
  final int passengerCount;

  const BookingScreen({
    super.key,
    required this.flightId,
    required this.flight,
    required this.selectedSeats,
    required this.passengerCount,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _api = ApiService();
  final List<TextEditingController> _nameControllers = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.passengerCount; i++) {
      _nameControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createBooking() async {
    // 1. Auth Check FIRST - force login if not authenticated
    final token = await _api.getToken();
    if (token == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: EldiyarTheme.cardBackground,
            title: const Text(
              'Login Required',
              style: TextStyle(color: EldiyarTheme.textPrimary),
            ),
            content: const Text(
              'You must be logged in to create a booking. Please log in first.',
              style: TextStyle(color: EldiyarTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: EldiyarTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Pop back to login screen
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EldiyarTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Validate passenger names
    for (int i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter name for passenger ${i + 1}'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
        return;
      }
    }

    setState(() => _isCreating = true);
    try {
      final tickets = [];
      for (int i = 0; i < widget.passengerCount; i++) {
        tickets.add({
          'passenger_name': _nameControllers[i].text.trim(),
          'seat_number': widget.selectedSeats[i],
        });
      }

      print('[BOOKING DEBUG] Creating booking with token (${token.length} chars)');
      final booking = await _api.createBooking({
        'flight_id': widget.flightId,
        'tickets': tickets,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(bookingId: booking['id']),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        String errorMessage = e.toString();
        
        // Handle 401 Unauthorized - token expired or invalid
        bool isAuthError = errorMessage.contains('401') || 
            errorMessage.contains('Unauthorized') ||
            errorMessage.contains('credentials');
            
        bool isProfileError =
            errorMessage.contains('Profile') ||
            errorMessage.contains('profile');

        if (isAuthError) {
          print('[BOOKING DEBUG] Auth error detected, redirecting to login');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: EldiyarTheme.cardBackground,
              title: const Text(
                'Session Expired',
                style: TextStyle(color: EldiyarTheme.textPrimary),
              ),
              content: const Text(
                'Your session has expired. Please log in again to continue.',
                style: TextStyle(color: EldiyarTheme.textSecondary),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EldiyarTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        } else if (isProfileError) {
          // Show dialog to go to profile
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: EldiyarTheme.cardBackground,
              title: const Text(
                'Profile Required',
                style: TextStyle(color: EldiyarTheme.textPrimary),
              ),
              content: const Text(
                'Please complete your passenger profile before booking. This includes passport number, phone number, nationality, and date of birth.',
                style: TextStyle(color: EldiyarTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EldiyarTheme.primaryBlue.withOpacity(0.2),
                    foregroundColor: EldiyarTheme.primaryBlue,
                  ),
                  child: const Text('Go to Profile'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating booking: $e'),
              backgroundColor: EldiyarTheme.errorRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
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
                      'Flight: ${widget.flight['flight_number']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${widget.flight['origin']['code']} → ${widget.flight['destination']['code']}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Price: \$${(widget.flight['base_price'] * widget.passengerCount).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Passenger Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.passengerCount, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Seat: ${widget.selectedSeats[index]}'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isCreating ? null : _createBooking,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : const Text('Create Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
