import 'package:flutter/material.dart';
import '../../models/flight.dart';

class ManageFlightsScreen extends StatelessWidget {
  const ManageFlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Обычно flights загружаются через API
    final mockFlights = [
      Flight(
        id: 0,
        flightNumber: "BA303",
        originCode: "LHR",
        destinationCode: "IST",
        departureTime: DateTime(2026, 1, 12, 18, 00),
        arrivalTime: DateTime(2026, 1, 12, 23, 20),
        price: 510.0,
        status: "SCHEDULED",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Flights')),
      body: ListView.builder(
        itemCount: mockFlights.length,
        itemBuilder: (_, i) {
          final f = mockFlights[i];
          return Card(
            child: ListTile(
              title: Text('${f.flightNumber} ${f.originCode} → ${f.destinationCode}'),
              subtitle: Text('Status: ${f.status}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'DELAYED', child: Text('Mark Delayed')),
                  PopupMenuItem(value: 'CANCELLED', child: Text('Cancel Flight')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}