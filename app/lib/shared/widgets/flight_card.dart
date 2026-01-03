import 'package:flutter/material.dart';
import '../models/flight.dart';
import '../models/enums.dart';
import '../utils/formatters.dart';

class FlightCard extends StatelessWidget {
  final Flight flight;
  final VoidCallback? onTap;

  const FlightCard({
    super.key,
    required this.flight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    flight.flightNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.origin?.code ?? '',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          Formatters.formatTime(flight.departureTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.flight_takeoff, color: Colors.grey[600]),
                        Text(
                          flight.durationMinutes != null
                              ? Formatters.formatDurationMinutes(
                                  flight.durationMinutes!)
                              : Formatters.formatDuration(flight.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          flight.destination?.code ?? '',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          Formatters.formatTime(flight.arrivalTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatPrice(flight.basePrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (flight.availableSeats != null)
                    Text(
                      '${flight.availableSeats} seats available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    if (flight.status == FlightStatus.SCHEDULED) {
      color = Colors.green;
    } else if (flight.status == FlightStatus.BOARDING) {
      color = Colors.orange;
    } else if (flight.status == FlightStatus.DELAYED) {
      color = Colors.red;
    } else if (flight.status == FlightStatus.CANCELLED) {
      color = Colors.grey;
    } else if (flight.status == FlightStatus.DEPARTED) {
      color = Colors.blue;
    } else if (flight.status == FlightStatus.LANDED) {
      color = Colors.teal;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        flight.status.name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

