import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/flight.dart';
import '../services/flight_service.dart';
import '../providers/auth_provider.dart';
import 'booking_seat_selection_screen.dart';
import '../core/theme/app_theme.dart';
import 'package:dio/dio.dart';

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

class FlightDetailsScreen extends ConsumerStatefulWidget {
  final int flightId;

  const FlightDetailsScreen({super.key, required this.flightId});

  @override
  ConsumerState<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends ConsumerState<FlightDetailsScreen> {
  Flight? _flight;
  List<SeatStatus>? _seats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFlightDetails();
  }

  Future<void> _loadFlightDetails() async {
    try {
      final flightService = ref.read(flightServiceProvider);
      final authState = ref.read(authProvider);
      
      // Load flight details and seats in parallel
      final results = await Future.wait([
        flightService.getFlightDetails(widget.flightId),
        flightService.getFlightSeats(
          widget.flightId,
          token: authState.token,
        ),
      ]);
      
      final flight = results[0] as Flight;
      final seats = results[1] as List<SeatStatus>;
      
      if (mounted) {
        setState(() {
          _flight = flight;
          _seats = seats;
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

  int _getAvailableSeatsCount() {
    if (_seats == null) return 0;
    return _seats!.where((seat) => !seat.isOccupied && !seat.isHeld).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null || _flight == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    final flight = _flight!;
    final duration = flight.arrivalTime.difference(flight.departureTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Flight Details',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Route Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flight.departureAirportCode,
                                    style: GoogleFonts.outfit(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('HH:mm').format(flight.departureTime),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.flight_takeoff, color: Colors.blue, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${hours}h ${minutes}m',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    flight.arrivalAirportCode,
                                    style: GoogleFonts.outfit(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('HH:mm').format(flight.arrivalTime),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // Flight Info Rows
                    _buildInfoRow('Airline', 'Astra Air'),
                    _buildInfoRow('Flight Number', flight.flightNumber),
                    _buildInfoRow('Aircraft Type', 'Boeing 787 Dreamliner'),
                    _buildInfoRow('Price', '\$${flight.basePrice.toInt()}'),
                    _buildInfoRow('Available Seats', '${_getAvailableSeatsCount()}'),
                    if (flight.gate != null)
                      _buildInfoRow('Gate', flight.gate!),
                    if (flight.terminal != null)
                      _buildInfoRow('Terminal', flight.terminal!),
                  ],
                ),
              ),
            ),
            
            // Choose Seat Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingSeatSelectionScreen(flight: flight),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6), // Bright Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Choose Seat',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white54, // Muted white
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

