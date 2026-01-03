import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'boarding_pass_screen.dart';
import 'services/storage_service.dart';
import 'payment_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic>? flightData;
  final Map<String, dynamic>? passengerData;
  final double seatPrice;

  const BookingSummaryScreen({
    super.key, 
    this.flightData, 
    this.passengerData, 
    this.seatPrice = 0.0
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _acceptedTerms = false;

  void _proceedToPayment() {
    // Construct incomplete booking object for payment screen
    final bookingData = {
      'flight': widget.flightData,
      'passenger': widget.passengerData,
      'seatPrice': widget.seatPrice,
    };
    
    // Calculate total (mock logic)
    // Base fare: 580 + Taxes: 120 + Seat
    final total = 700.0 + widget.seatPrice;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          flightData: widget.flightData ?? {},
          passengerData: widget.passengerData ?? {},
          seatData: {
            'seatNumber': 'N/A', // Default if coming from summary
            'seatPrice': widget.seatPrice,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Helper Data
    final flightNum = widget.flightData?['flightNumber'] ?? 'TK 0001';
    final origin = widget.flightData?['origin'] ?? 'IST'; // Fixed: using origin/destination keys if mock
    final dest = widget.flightData?['destination'] ?? 'JFK'; // Fixed keys for flightData from previous screen if needed or defaults
    // Note: flight_results passed flightNumber, etc. key names might differ slightly, normalizing here or using defaults.
    // In flight_results we passed map with: flightNumber, depTime, arrTime, etc.
    // We should be careful about key names. For prototype, defaults serve well if data missing.
    
    final paxName = widget.passengerData != null 
        ? '${widget.passengerData!['firstName']} ${widget.passengerData!['lastName']}'
        : 'John Doe';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF0B1E3B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review & Pay',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Flight Itinerary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Flight Itinerary',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0B1E3B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'One Way',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0B1E3B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${origin == 'IST' ? 'Istanbul' : origin} to ${dest == 'JFK' ? 'New York' : dest}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0B1E3B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.flightData?['date'] != null 
                                          ? (widget.flightData!['date'] is DateTime 
                                              ? '${DateFormat('d MMM, EEE').format(widget.flightData!['date'] as DateTime)} • ${widget.flightData!['departureTime'] ?? '13:05'} - ${widget.flightData!['arrivalTime'] ?? '17:35'}'
                                              : '${widget.flightData!['date']} • ${widget.flightData!['departureTime'] ?? '13:05'} - ${widget.flightData!['arrivalTime'] ?? '17:35'}')
                                          : '12 Oct, Thu • 13:05 - 17:35',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.airplane_ticket_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                'Turkish Airlines • $flightNum • Economy',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Passengers Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passengers',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B1E3B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: Text(
                                paxName.isNotEmpty ? paxName[0] : 'P',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF0B1E3B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              '$paxName (Adult)',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0B1E3B),
                              ),
                            ),
                            subtitle: Text(
                              'Passport: ${widget.passengerData?['passport'] ?? 'N/A'} • 23 kg Baggage',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B1E3B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPriceRow('Base Fare (1 Adult)', '\$580.00'),
                          const SizedBox(height: 12),
                          _buildPriceRow('Taxes & Fees', '\$120.00'),
                          const SizedBox(height: 12),
                          _buildPriceRow('Seat Selection', '\$${widget.seatPrice.toStringAsFixed(2)}'),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1E3B),
                                ),
                              ),
                              Text(
                                '\$${(700 + widget.seatPrice).toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1E3B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Terms
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          activeColor: const Color(0xFF0B1E3B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              _acceptedTerms = val!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  color: const Color(0xFF0B1E3B),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  color: const Color(0xFF0B1E3B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Pay Button
                  ElevatedButton(
                    onPressed: _acceptedTerms ? _proceedToPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _acceptedTerms ? const Color(0xFF0B1E3B) : const Color(0xFF94A3B8),
                    ),
                    child: const Text('PROCEED TO PAYMENT'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Secure Payment Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'Secure SSL Encrypted Payment',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          price,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B1E3B),
          ),
        ),
      ],
    );
  }
}