import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flight.dart';
import '../models/booking.dart';
import '../services/flight_service.dart';
import '../services/booking_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'booking_details_screen.dart';
import 'payment_screen.dart';
import 'my_trips_screen.dart';
import 'flight_search_screen.dart';
import 'passenger_main_screen.dart';
import 'package:dio/dio.dart';
import 'seat_map_screen.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

class BookingSeatSelectionScreen extends ConsumerStatefulWidget {
  final Flight flight;

  const BookingSeatSelectionScreen({super.key, required this.flight});

  @override
  ConsumerState<BookingSeatSelectionScreen> createState() => _BookingSeatSelectionScreenState();
}

class _BookingSeatSelectionScreenState extends ConsumerState<BookingSeatSelectionScreen> {
  List<SeatStatus> _seats = [];
  // For simplicity relative to the request, we'll assume 1 passenger or handle multiple better
  // But let's stick to the current logic of allowing multiple passengers
  List<TextEditingController> _passengerControllers = [TextEditingController()];
  List<TextEditingController> _passportControllers = [TextEditingController()];
  Map<int, String?> _selectedSeats = {}; // passengerIndex -> seatNumber
  bool _isLoading = true;
  bool _isBooking = false;
  int _activePassengerIndex = 0; // Which passenger is currently selecting a seat

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  @override
  void dispose() {
    for (var controller in _passengerControllers) {
      controller.dispose();
    }
    for (var controller in _passportControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSeats() async {
    try {
      final authState = ref.read(authProvider);
      final flightService = ref.read(flightServiceProvider);
      final seats = await flightService.getFlightSeats(
        widget.flight.id,
        token: authState.token,
      );
      
      if (mounted) {
        setState(() {
          _seats = seats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seats: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addPassenger() {
    setState(() {
      _passengerControllers.add(TextEditingController());
      _passportControllers.add(TextEditingController());
    });
  }

  void _removePassenger(int index) {
    if (_passengerControllers.length > 1) {
      setState(() {
        _passengerControllers[index].dispose();
        _passportControllers[index].dispose();
        _passengerControllers.removeAt(index);
        _passportControllers.removeAt(index);
        
        // Adjust selected seats
        final seatToRelease = _selectedSeats[index];
        _selectedSeats.remove(index);
        
        // Shift remaining selections down if needed? 
        // Simpler to just reset selections for indexes > removed index or re-map
        // For now, let's just clear selections for simplified logic or keep as is map-based
        // Clean up backend holds
        if (seatToRelease != null) {
          _releaseSeatsOnBackend([seatToRelease]);
        }
        
        // Reset active passenger if it was the removed one
        if (_activePassengerIndex >= _passengerControllers.length) {
          _activePassengerIndex = _passengerControllers.length - 1;
        }
      });
    }
  }

  Future<void> _holdSeatsOnBackend(List<String> seatNumbers) async {
    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) return;
      
      final flightService = ref.read(flightServiceProvider);
      await flightService.holdSeats(
        widget.flight.id,
        seatNumbers,
        authState.token!,
      );
    } catch (e) {
      print('Error holding seats on backend: $e');
    }
  }

  Future<void> _releaseSeatsOnBackend(List<String> seatNumbers) async {
    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) return;
      
      final flightService = ref.read(flightServiceProvider);
      await flightService.releaseSeats(
        widget.flight.id,
        seatNumbers,
        authState.token!,
      );
    } catch (e) {
      print('Error releasing seats on backend: $e');
    }
  }

  Future<void> _showPaymentOptionDialog() async {
    // Validate
    for (int i = 0; i < _passengerControllers.length; i++) {
      if (_passengerControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter name for passenger ${i + 1}')),
        );
        return;
      }
      if (_passportControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter passport number for passenger ${i + 1}')),
        );
        return;
      }
      if (!_selectedSeats.containsKey(i)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a seat for passenger ${i + 1}')),
        );
        return;
      }
    }

    // Show payment option dialog
    final paymentOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Payment Option',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your payment option',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, 'pay_now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'pay_later'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Later',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (paymentOption == null) return;

    // Create booking
    await _createBooking(paymentOption == 'pay_now');
  }

  Future<void> _createBooking(bool payNow) async {
    setState(() {
      _isBooking = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        throw Exception('Not authenticated');
      }

      final passengers = _passengerControllers.asMap().entries.map((entry) {
        return PassengerInfo(
          passengerName: entry.value.text.trim(),
          passportNumber: _passportControllers[entry.key].text.trim(),
          seatNumber: _selectedSeats[entry.key],
        );
      }).toList();

      final bookingService = ref.read(bookingServiceProvider);
      final booking = await bookingService.createBooking(
        token: authState.token!,
        bookingData: BookingCreate(
          flightId: widget.flight.id,
          passengers: passengers,
        ),
      );

      // Release any remaining holds (booking will take over)
      final heldSeatNumbers = List<String>.from(_selectedSeats.values.whereType<String>());
      if (heldSeatNumbers.isNotEmpty) {
        _releaseSeatsOnBackend(heldSeatNumbers);
      }

      if (mounted) {
        if (payNow) {
          // Navigate to payment screen - PaymentScreen will handle navigation to My Trips after payment
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                bookingId: booking.id,
                amount: booking.totalPrice,
              ),
            ),
          );
          // PaymentScreen will navigate to My Trips after successful payment
        } else {
          // Pay Later - navigate back to PassengerMainScreen and switch to My Trips tab
          // Close all screens until we reach the main screen
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Switch to My Trips tab (index 1)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentTabIndexProvider).value = 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Future<void> _openSeatMap(int passengerIndex) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SeatMapScreen(
          flight: widget.flight,
          selectedSeat: _selectedSeats[passengerIndex],
        ),
      ),
    );

    if (result != null) {
      // Check if selected by another passenger locally (edge case if backend hold didn't reflect yet or race condition)
      bool takenByOther = false;
      _selectedSeats.forEach((key, value) {
        if (key != passengerIndex && value == result) {
          takenByOther = true;
        }
      });

      if (takenByOther) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Seat already selected by another passenger')),
          );
        }
        return;
      }

      setState(() {
          final oldSeat = _selectedSeats[passengerIndex];
          if (oldSeat != null) {
              _releaseSeatsOnBackend([oldSeat]);
          }
          
          _selectedSeats[passengerIndex] = result;
          _holdSeatsOnBackend([result]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Choose your seat'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Step 4 of 5',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // 2. Route & Date Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.flight.departureAirportCode} → ${widget.flight.arrivalAirportCode}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, MMM d • HH:mm').format(widget.flight.departureTime),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.flight.flightNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 32, color: Color(0xFF334155)), // Slate 700

                // 3. Passenger Selection Tabs (if multiple)
                if (_passengerControllers.length > 0)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _passengerControllers.length + 1, // +1 for Add button
                      itemBuilder: (context, index) {
                        if (index == _passengerControllers.length) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              onPressed: _addPassenger,
                              icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryColor),
                            ),
                          );
                        }
                        
                        final isSelected = _activePassengerIndex == index;
                        final hasSeat = _selectedSeats.containsKey(index);
                        
                        return GestureDetector(
                          onTap: () => setState(() => _activePassengerIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.user, 
                                  size: 16, 
                                  color: isSelected ? Colors.white : AppTheme.textSecondary
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Passenger ${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (hasSeat) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                                  ),
                                ],
                                if (_passengerControllers.length > 1 && isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: InkWell(
                                      onTap: () => _removePassenger(index),
                                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white70),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // 4. Passenger Inputs
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                   child: Column(
                     children: [
                       TextField(
                         controller: _passengerControllers[_activePassengerIndex],
                         style: const TextStyle(color: Colors.white),
                         decoration: InputDecoration(
                           labelText: 'Full Name',
                           prefixIcon: const Icon(LucideIcons.user, color: AppTheme.textSecondary),
                           filled: true,
                           fillColor: AppTheme.surfaceColor,
                         ),
                       ),
                       const SizedBox(height: 8),
                       TextField(
                         controller: _passportControllers[_activePassengerIndex],
                         style: const TextStyle(color: Colors.white),
                         decoration: InputDecoration(
                           labelText: 'Passport Number',
                           prefixIcon: const Icon(LucideIcons.creditCard, color: AppTheme.textSecondary), // or generic card icon
                           filled: true,
                           fillColor: AppTheme.surfaceColor,
                         ),
                       ),
                     ],
                   ),
                 ),

                const SizedBox(height: 16),

                // 5. Seat Selection Button
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _openSeatMap(_activePassengerIndex),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.armchair, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Select Seat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedSeats.containsKey(_activePassengerIndex))
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primaryColor),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Selected Seat',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedSeats[_activePassengerIndex] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${(widget.flight.basePrice * _passengerControllers.length).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _showPaymentOptionDialog,
                  child: _isBooking
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

