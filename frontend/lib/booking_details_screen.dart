import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'boarding_pass_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late Map<String, dynamic> _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      await StorageService().updateBookingStatus(_booking['pnr'], 'CANCELLED');
      
      setState(() {
        _booking['status'] = 'CANCELLED';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flight = _booking['flight'];
    final passenger = _booking['passenger'];
    final status = _booking['status'] ?? 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0B1E3B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true), // Return true to trigger refresh
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCancelled ? Colors.red : Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                          color: isCancelled ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isCancelled ? 'Booking Cancelled' : 'Booking Confirmed',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: isCancelled ? Colors.red : Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Flight Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flight Information', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildDetailRow('Airline', 'Turkish Airlines'),
                          _buildDetailRow('Flight', flight['flightNumber'] ?? 'TK 0001'),
                          _buildDetailRow('Route', '${flight['origin']} - ${flight['destination']}'),
                          _buildDetailRow('Date', flight['date'] ?? '12 Oct 2023'),
                          _buildDetailRow('Time', flight['time'] ?? '13:05'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Passenger Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passenger Details', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildDetailRow('Name', '${passenger['firstName']} ${passenger['lastName']}'),
                          _buildDetailRow('Passport', passenger['passport'] ?? 'N/A'),
                          _buildDetailRow('Email', passenger['email'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                   // Payment Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Summary', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildDetailRow('Total Amount', '\$720.00'), // Replace with actual if stored
                          _buildDetailRow('Payment Method', 'Credit Card (**** 1234)'),
                          _buildDetailRow('Status', isCancelled ? 'Refunded' : 'Paid'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!isCancelled) ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BoardingPassScreen(booking: _booking)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1E3B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('VIEW BOARDING PASS'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cancelBooking,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CANCEL BOOKING'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF0B1E3B))),
        ],
      ),
    );
  }
}
