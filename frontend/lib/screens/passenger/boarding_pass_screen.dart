import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/ticket.dart';

class BoardingPassScreen extends StatelessWidget {
  final Ticket ticket;

  const BoardingPassScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boarding Pass')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.passengerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Flight: ${ticket.flightNumber}'),
            Text('Seat: ${ticket.seat}'),
            if (ticket.passportNumber != null) Text('Passport: ${ticket.passportNumber}'),
            if (ticket.nationality != null) Text('Nationality: ${ticket.nationality}'),
            Text('Gate: ${ticket.gate}'),
            Text('Boarding: ${ticket.boardingTime}'),
            const SizedBox(height: 30),
            Center(child: QrImageView(data: ticket.qrData ?? '', size: 240)),
          ],
        ),
      ),
    );
  }
}
