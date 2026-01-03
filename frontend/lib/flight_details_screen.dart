import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'passenger_info_screen.dart';

class FlightDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> flightData;
  const FlightDetailsScreen({super.key, this.flightData = const {}});

  @override
  Widget build(BuildContext context) {
    // Helper accessors
    final String flightNumber = flightData['flightNumber'] ?? 'TK 0001';
    final String fromCode = flightData['from'] ?? 'IST';
    final String toCode = flightData['to'] ?? 'JFK';
    final String depTime = flightData['departureTime'] ?? '13:05';
    final String arrTime = flightData['arrivalTime'] ?? '17:35';
    final String duration = flightData['duration'] ?? '11h 30m';
    final double price = flightData['price'] ?? 720.0;
    
    // Formatting Date
    String dateStr = '12 Oct, Thu';
    if (flightData['date'] != null) {
      if (flightData['date'] is DateTime) {
        dateStr = DateFormat('d MMM, EEE').format(flightData['date']);
      } else if (flightData['date'] is String) {
        dateStr = flightData['date']; 
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF0B1E3B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Flight Details',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Upper Route Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fromCode,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B1E3B),
                            ),
                          ),
                          Text(
                            '$dateStr, $depTime',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFFC59D5F)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            toCode,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B1E3B),
                            ),
                          ),
                          Text(
                            '$dateStr, $arrTime',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Flight Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Airline & Flight No
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0B1E3B), // Logo placeholder
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flight_takeoff_rounded,
                                    size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Turkish Airlines',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B1E3B),
                                    ),
                                  ),
                                  Text(
                                    '$flightNumber • Boeing 777-300ER',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Economy',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Timeline
                          _buildTimelineStep(
                            time: depTime,
                            date: dateStr,
                            city: fromCode == 'IST' ? 'Istanbul' : fromCode,
                            airport: '$fromCode Airport',
                            terminal: 'Terminal I',
                            isStart: true,
                          ),
                          _buildTimelineConnector(
                            duration: duration,
                          ),
                          _buildTimelineStep(
                            time: arrTime,
                            date: dateStr,
                            city: toCode == 'JFK' ? 'New York' : toCode,
                            airport: '$toCode Intl.',
                            terminal: 'Terminal 1',
                            isEnd: true,
                          ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Amenities Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAmenity(Icons.luggage_rounded, '2x23 kg'),
                              _buildAmenity(Icons.restaurant_rounded, 'Hot Meal'),
                              _buildAmenity(Icons.wifi_rounded, 'Wi-Fi'),
                              _buildAmenity(Icons.tv_rounded, 'Movies'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Important Info Card
                  Card(
                    color: const Color(0xFFFDFCF8), // Very subtle warm tint
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF2E9D8)), // Light gold border
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFC59D5F)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Arrive at airport 3 hours before departure for international flights.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF0B1E3B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1E3B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PassengerInfoScreen(
                            selectedFlight: flightData,
                          ),
                        ),
                      );
                    },
                    child: const Text('SELECT FLIGHT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String time,
    required String date,
    required String city,
    required String airport,
    String? terminal,
    bool isStart = false,
    bool isEnd = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1E3B),
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Line Column
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isStart || isEnd ? const Color(0xFF0B1E3B) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                  border: isStart || isEnd 
                      ? Border.all(color: const Color(0xFFC59D5F), width: 3)
                      : null,
                ),
              ),
              if (!isEnd)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1E3B),
                  ),
                ),
                Text(
                  airport,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (terminal != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      terminal,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // Add some bottom padding if not end to space out the connector
                if (!isEnd) const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector({required String duration}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 76), // Match spacing of Time + Gap
          SizedBox(
            width: 12,
            child: Center(
              child: Container(
                width: 2,
                color: const Color(0xFFE2E8F0),
                height: 40,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF0B1E3B), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}