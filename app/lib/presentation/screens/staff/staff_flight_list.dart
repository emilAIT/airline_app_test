import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/domain/entities/flight.dart';
import 'package:airline_app/presentation/cubits/staff_cubit.dart';

class StaffFlightList extends StatelessWidget {
  final List<Flight> flights;
  const StaffFlightList({super.key, required this.flights});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      flight.flightNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _StatusBadge(status: flight.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${flight.origin.code} ➔ ${flight.destination.code}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Update Status:', style: TextStyle(fontSize: 12)),
                    DropdownButton<String>(
                      value: flight.status.name.toUpperCase(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          context.read<StaffCubit>().updateFlightStatus(flight.id, newStatus);
                        }
                      },
                      items: FlightStatus.values.map((s) {
                        final name = s.name.toUpperCase();
                        return DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FlightStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (status == FlightStatus.delayed) color = Colors.orange;
    if (status == FlightStatus.cancelled) color = Colors.red;
    if (status == FlightStatus.landed) color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
