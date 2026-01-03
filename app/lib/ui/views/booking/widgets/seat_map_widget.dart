import 'package:flutter/material.dart';
import '../../../../models/seat_model.dart';
import '../booking_viewmodel.dart';

class SeatMapWidget extends StatelessWidget {
  final SeatMapResponse seatMap;
  final List<PassengerData> passengers;
  final Function(int passengerIndex, String? seatId) onSeatSelected;

  const SeatMapWidget({
    Key? key,
    required this.seatMap,
    required this.passengers,
    required this.onSeatSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group seats by row
    final seatsByRow = <int, List<FlightSeat>>{};
    for (var seat in seatMap.seats) {
      if (!seatsByRow.containsKey(seat.row)) {
        seatsByRow[seat.row] = [];
      }
      seatsByRow[seat.row]!.add(seat);
    }

    // Sort rows
    final sortedRows = seatsByRow.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildLegend(),
        const SizedBox(height: 16),
        // Seat map
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flight, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Cabin Layout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Rows
              ...sortedRows.map((row) => _buildSeatRow(row, seatsByRow[row]!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.green, 'Available'),
          _buildLegendItem(Colors.red, 'Booked'),
          _buildLegendItem(Colors.orange, 'Selected'),
          _buildLegendItem(Colors.grey, 'Blocked'),
        ],
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
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildSeatRow(int row, List<FlightSeat> seats) {
    // Sort seats by seat_label (create a copy to avoid modifying the original list)
    final sortedSeats = List<FlightSeat>.from(seats);
    sortedSeats.sort((a, b) => a.seatLabel.compareTo(b.seatLabel));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row number
          SizedBox(
            width: 40,
            child: Text(
              '$row',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Seats
          ...sortedSeats.map((seat) => _buildSeatButton(seat)),
        ],
      ),
    );
  }

  Widget _buildSeatButton(FlightSeat seat) {
    // Find which passenger has this seat selected
    int? selectedByPassenger;
    for (int i = 0; i < passengers.length; i++) {
      if (passengers[i].selectedSeatId == seat.id) {
        selectedByPassenger = i;
        break;
      }
    }

    Color seatColor;
    if (selectedByPassenger != null) {
      seatColor = Colors.orange;
    } else if (seat.status == FlightSeatStatus.available) {
      seatColor = Colors.green;
    } else if (seat.status == FlightSeatStatus.booked) {
      seatColor = Colors.red;
    } else {
      seatColor = Colors.grey;
    }

    final isSelectable = seat.status == FlightSeatStatus.available &&
        selectedByPassenger == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: isSelectable
            ? () {
                // Find first passenger without a seat
                for (int i = 0; i < passengers.length; i++) {
                  if (passengers[i].selectedSeatId == null) {
                    onSeatSelected(i, seat.id);
                    return;
                  }
                }
                // If all passengers have seats, allow reselection
                onSeatSelected(0, seat.id);
              }
            : selectedByPassenger != null
                ? () {
                    // Allow deselecting seat
                    onSeatSelected(selectedByPassenger!, null);
                  }
                : null,
        child: Tooltip(
          message: selectedByPassenger != null
              ? 'Passenger ${selectedByPassenger! + 1}'
              : seat.status == FlightSeatStatus.available
                  ? 'Available - Tap to select'
                  : seat.status == FlightSeatStatus.booked
                      ? 'Booked'
                      : 'Blocked',
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: seatColor.withOpacity(0.3),
              border: Border.all(
                color: seatColor,
                width: selectedByPassenger != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seat.seatLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selectedByPassenger != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: seatColor,
                    ),
                  ),
                  if (selectedByPassenger != null)
                    Text(
                      'P${selectedByPassenger! + 1}',
                      style: TextStyle(
                        fontSize: 8,
                        color: seatColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

