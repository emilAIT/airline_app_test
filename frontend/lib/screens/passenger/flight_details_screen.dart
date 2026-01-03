import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/seat.dart';
import '../../providers/booking_provider.dart';
import 'payment_screen.dart';

class FlightDetailsScreen extends StatefulWidget {
  final int flightId;

  const FlightDetailsScreen({
    super.key,
    required this.flightId,
  });

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  String? selectedSeat;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<BookingProvider>().fetchSeatMap(widget.flightId));
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final seats = bookingProvider.seats;

    return Scaffold(
      appBar: AppBar(title: const Text('Select seat')),
      body: Column(
        children: [
          // ⚠️ ERROR MESSAGE
          if (bookingProvider.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Text(
                bookingProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // ⚠️ PROFILE WARNING
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: const Text(
              'Make sure your passenger profile is completed',
              style: TextStyle(color: Colors.black87),
            ),
          ),

          const SizedBox(height: 10),

          // 🪑 SEATS GRID
          Expanded(
            child: bookingProvider.loading && seats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
                    crossAxisCount: 6,
                    padding: const EdgeInsets.all(12),
                    children: seats.map(_seatTile).toList(),
                  ),
          ),

          // 🔘 BOOK BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selectedSeat == null || bookingProvider.loading
                  ? null
                  : () async {
                      // 1️⃣ Hold seat
                      final held = await bookingProvider.holdSeats(
                        widget.flightId,
                        [selectedSeat!],
                      );

                      if (!held) return;

                      // 2️⃣ Create booking
                      await bookingProvider.create(
                        widget.flightId,
                        [selectedSeat!],
                      );

                      if (bookingProvider.booking != null && mounted) {
                        final success = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentScreen(),
                          ),
                        );

                        if (success == true && mounted) {
                          // Go back to Home
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment Successful! Your flight is booked.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              child: bookingProvider.loading
                  ? const CircularProgressIndicator()
                  : const Text('Book & Pay'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seatTile(Seat seat) {
    final isSelected = seat.seatNumber == selectedSeat;

    Color color;
    if (seat.status == SeatStatus.occupied) {
      color = Colors.red;
    } else if (seat.status == SeatStatus.held) {
      color = Colors.orange;
    } else if (isSelected) {
      color = Colors.green;
    } else {
      color = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: seat.isSelectable
          ? () => setState(() => selectedSeat = seat.seatNumber)
          : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            seat.seatNumber,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
