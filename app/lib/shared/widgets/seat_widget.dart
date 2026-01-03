import 'package:flutter/material.dart';
import '../models/seat.dart';
import '../models/enums.dart';

class SeatWidget extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final VoidCallback? onTap;

  const SeatWidget({
    super.key,
    required this.seat,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (isSelected) {
      color = Colors.blue;
      icon = Icons.event_seat;
    } else if (!seat.isAvailable) {
      color = Colors.grey;
      icon = Icons.event_seat;
    } else if (seat.category == SeatCategory.EXTRA_LEGROOM) {
      color = Colors.green;
      icon = Icons.event_seat;
    } else {
      color = Colors.grey[300]!;
      icon = Icons.event_seat;
    }

    return InkWell(
      onTap: seat.isAvailable && !isSelected ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            Text(
              seat.seatNumber,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.grey[300]!, 'Available'),
            const SizedBox(height: 4),
            _buildLegendItem(Colors.green, 'Extra Legroom'),
            const SizedBox(height: 4),
            _buildLegendItem(Colors.blue, 'Selected'),
            const SizedBox(height: 4),
            _buildLegendItem(Colors.grey, 'Occupied'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

