import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/flight_cubit.dart';
import 'seat_selection_screen.dart';

class FlightDetailsScreen extends StatefulWidget {
  final int flightId;
  const FlightDetailsScreen({super.key, required this.flightId});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FlightCubit>().getDetails(widget.flightId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flight Details')),
      body: BlocBuilder<FlightCubit, FlightState>(
        builder: (context, state) {
          if (state is FlightLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FlightDetailLoaded) {
            final detail = state.detail;
            final flight = detail['flight'];
            
            // Add null safety checks
            if (flight == null) {
              return const Center(child: Text('Flight data not available'));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailCard(
                    title: 'Route',
                    content: '${flight['origin_airport']?['city'] ?? 'N/A'} (${flight['origin_airport']?['code'] ?? 'N/A'}) → ${flight['destination_airport']?['city'] ?? 'N/A'} (${flight['destination_airport']?['code'] ?? 'N/A'})',
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    title: 'Schedule',
                    content: 'Departure: ${DateFormat('EEE, d MMM HH:mm').format(DateTime.parse(flight['scheduled_departure'] ?? DateTime.now().toIso8601String()))}\nArrival: ${DateFormat('EEE, d MMM HH:mm').format(DateTime.parse(flight['scheduled_arrival'] ?? DateTime.now().toIso8601String()))}',
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    title: 'Aircraft',
                    content: '${flight['airplane']?['model'] ?? 'N/A'} (${flight['airplane']?['registration_number'] ?? 'N/A'})',
                    icon: Icons.airplanemode_active,
                  ),
                  const SizedBox(height: 16),
                  _DetailCard(
                    title: 'Terminal & Gate',
                    content: 'Terminal: ${flight['terminal'] ?? 'T1'} | Gate: ${flight['gate'] ?? 'G12'}',
                    icon: Icons.door_front_door_outlined,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeatSelectionScreen(
                            flightId: widget.flightId,
                            seatTemplate: flight['airplane']?['seat_template'] ?? {},
                          ),
                        ),
                      );
                    },
                    child: const Text('SELECT SEATS'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Unexpected state'));
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
