import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';

class BoardingPassScreen extends StatelessWidget {
  final Map<String, dynamic>? booking;

  const BoardingPassScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    // Helper Data (support both nested and flat structures)
    final pnr = booking?['pnr'] ?? booking?['bookingId'] ?? 'PNR12345';
    final flight = booking?['flight'];
    final passenger = booking?['passenger'];
    
    final flightNum = flight?['flightNumber'] ?? booking?['flightNumber'] ?? 'TK 0001';
    final origin = flight?['origin'] ?? booking?['from'] ?? 'IST';
    final destination = flight?['destination'] ?? booking?['to'] ?? 'JFK';
    
    final dynamic dateVal = flight?['date'] ?? booking?['date'];
    final String date = dateVal != null 
        ? (dateVal is DateTime 
            ? DateFormat('d MMM').format(dateVal) 
            : (DateTime.tryParse(dateVal.toString()) != null 
                ? DateFormat('d MMM').format(DateTime.parse(dateVal.toString()))
                : dateVal.toString()))
        : '12 Oct';
        
    final time = flight?['time'] ?? booking?['departureTime'] ?? '13:05';
    
    final paxName = booking?['passengerName'] ?? 
        (passenger != null ? '${passenger['firstName']} ${passenger['lastName']}' : 'John Doe');

    final gate = booking?['gate'] ?? 'A12';
    final seat = booking?['seat'] ?? booking?['seatNumber'] ?? '14A';

    final qrData = 'PNR:$pnr|FLT:$flightNum|DATE:$date|PAX:$paxName';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () {
            // Return to Home (MainScreen which displays index 0 initially)
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const AirlineApp()), 
              (route) => false
            );
          },
        ),
        title: Text(
          'Mobile Boarding Pass',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          children: [
            // The Boarding Pass Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                   // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1E3B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(6),
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 border: Border.all(color: const Color(0xFFC59D5F)),
                               ),
                               child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFC59D5F), size: 16),
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'AERO PREMIER',
                               style: GoogleFonts.manrope(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w700,
                                 letterSpacing: 1.0,
                                 fontSize: 14,
                               ),
                             ),
                           ],
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             'ECONOMY',
                             style: GoogleFonts.manrope(
                               color: Colors.white,
                               fontSize: 10,
                               fontWeight: FontWeight.w700,
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),

                  // Route
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  origin,
                                  style: GoogleFonts.manrope(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1E3B),
                                  ),
                                ),
                                Text(
                                  'Origin',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: const Icon(Icons.flight_rounded, color: Color(0xFFC59D5F), size: 24),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  destination,
                                  style: GoogleFonts.manrope(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1E3B),
                                  ),
                                ),
                                Text(
                                  'Destination',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('Flight', flightNum),
                            _buildInfoColumn('Date', date),
                            _buildInfoColumn('Boarding', time),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('Gate', gate, isHighlight: true),
                            _buildInfoColumn('Seat', seat, isHighlight: true),
                            _buildInfoColumn('Zone', 'C'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tear-off Line
                  SizedBox(
                    height: 24,
                    child: Stack(
                      children: [
                        const Center(
                          child: Divider(
                            color: Color(0xFFE2E8F0),
                            thickness: 1,
                            indent: 24,
                            endIndent: 24,
                            height: 1,
                          ),
                        ),
                        Positioned(
                          left: -12,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B1E3B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -12,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B1E3B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Passenger',
                                   style: GoogleFonts.manrope(
                                     fontSize: 12,
                                     color: const Color(0xFF64748B),
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   paxName,
                                   style: GoogleFonts.manrope(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w700,
                                     color: const Color(0xFF0B1E3B),
                                   ),
                                 ),
                               ],
                             ),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFF0FDF4),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Text(
                                 'TSA PRE',
                                 style: GoogleFonts.manrope(
                                   fontSize: 11,
                                   fontWeight: FontWeight.w700,
                                   color: const Color(0xFF15803D),
                                 ),
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // QR Code
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 150.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pnr,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Primary action - Download/Share
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDownloadOptions(context);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        'DOWNLOAD BOARDING PASS',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1E3B),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _shareBoardingPass(context);
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(
                            'Share',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0B1E3B),
                            side: const BorderSide(color: Color(0xFF0B1E3B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _addToWallet(context);
                          },
                          icon: const Icon(Icons.account_balance_wallet, size: 18),
                          label: Text(
                            'Add to Wallet',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0B1E3B),
                            side: const BorderSide(color: Color(0xFF0B1E3B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Options',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFBA1A1A)),
              title: Text('Download as PDF', style: GoogleFonts.manrope()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _downloadAsPDF(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF0B1E3B)),
              title: Text('Download as Image', style: GoogleFonts.manrope()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _downloadAsImage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFFC59D5F)),
              title: Text('Email to myself', style: GoogleFonts.manrope()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _emailBoardingPass(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadAsPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Boarding pass downloaded as PDF',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: const Color(0xFF166534),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            // Open PDF
          },
        ),
      ),
    );
  }

  void _downloadAsImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Boarding pass saved to gallery',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: const Color(0xFF166534),
      ),
    );
  }

  void _emailBoardingPass(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Boarding pass sent to ${booking?['passengerEmail'] ?? 'your email'}',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: const Color(0xFF166534),
      ),
    );
  }

  void _shareBoardingPass(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share options opened',
          style: GoogleFonts.manrope(),
        ),
        backgroundColor: const Color(0xFF0B1E3B),
      ),
    );
  }

  void _addToWallet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to Wallet', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.apple, size: 32),
              title: Text('Apple Wallet', style: GoogleFonts.manrope()),
              subtitle: Text('For iPhone users', style: GoogleFonts.manrope(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Apple Wallet...', style: GoogleFonts.manrope()),
                    backgroundColor: const Color(0xFF0B1E3B),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.android, size: 32, color: Color(0xFF3DDC84)),
              title: Text('Google Wallet', style: GoogleFonts.manrope()),
              subtitle: Text('For Android users', style: GoogleFonts.manrope(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Google Wallet...', style: GoogleFonts.manrope()),
                    backgroundColor: const Color(0xFF3DDC84),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: isHighlight ? 24 : 18,
            fontWeight: FontWeight.w800,
            color: isHighlight ? const Color(0xFF0B1E3B) : const Color(0xFF0B1E3B),
          ),
        ),
      ],
    );
  }
}
