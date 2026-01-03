import 'package:flutter/material.dart';

class FlightDetailsStaffPage extends StatelessWidget {
  final int flightId;

  const FlightDetailsStaffPage({super.key, required this.flightId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flight Details (Staff)')),
      body: const Center(child: Text('Staff view of flight with management options')),
    );
  }
}
