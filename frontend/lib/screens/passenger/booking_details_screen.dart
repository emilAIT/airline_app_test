import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/ticket.dart' as model;
import 'boarding_pass_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final flight = booking.flight;
    // Assuming one ticket for simplicity in this view, 
    // or we could show a list if multiple seats were booked.
    final ticket = booking.tickets.isNotEmpty ? booking.tickets.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PNR: ${booking.pnr}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _infoRow(Icons.event_seat, 'Seat', ticket?.seat ?? 'Not assigned'),
            _infoRow(Icons.flight, 'Flight', flight?.flightNumber ?? 'N/A'),
            _infoRow(Icons.door_sliding, 'Gate', 'TBD'), // Replace with flight.gate if available
            _infoRow(Icons.info_outline, 'Status', booking.status),
            
            const SizedBox(height: 30),
            
            if (ticket != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoardingPassScreen(
                        ticket: model.Ticket(
                          pnr: booking.pnr,
                          passengerName: ticket.passengerName,
                          flightNumber: flight?.flightNumber ?? '',
                          seat: ticket.seat,
                          gate: 'TBD',
                          boardingTime: 'Check screens',
                          qrData: ticket.ticketNumber ?? '',
                        ),
                      ),
                    ),
                  );
                },
                label: const Text('View Boarding Pass'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
