import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int flightId;
  final Map<String, dynamic> flight;

  const SeatSelectionScreen({
    super.key,
    required this.flightId,
    required this.flight,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _seats = [];
  List<String> _selectedSeats = [];
  int _passengerCount = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    try {
      final seatMap = await _api.getSeatMap(widget.flightId);
      setState(() {
        _seats = seatMap['seats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seat map: $e')),
        );
      }
    }
  }

  void _toggleSeat(String seatNumber) {
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        if (_selectedSeats.length < _passengerCount) {
          final seat = _seats.firstWhere((s) => s['seat_number'] == seatNumber);
          if (seat['is_available']) {
            _selectedSeats.add(seatNumber);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This seat is not available')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select $_passengerCount seat(s)'),
            ),
          );
        }
      }
    });
  }

  Widget _buildSeatWidget(dynamic seat) {
    final isSelected = _selectedSeats.contains(seat['seat_number']);
    final isAvailable = seat['is_available'] as bool;
    final isExtraLegroom = seat['category'] == 'EXTRA_LEGROOM';

    Color seatColor;
    if (isSelected) {
      seatColor = Colors.blue;
    } else if (!isAvailable) {
      seatColor = Colors.grey;
    } else if (isExtraLegroom) {
      seatColor = Colors.orange;
    } else {
      seatColor = Colors.green;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat['seat_number']),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            seat['seat_number'],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Group seats by row
    final Map<int, List<dynamic>> seatsByRow = {};
    for (var seat in _seats) {
      final row = seat['row'] as int? ?? 0;
      if (!seatsByRow.containsKey(row)) {
        seatsByRow[row] = [];
      }
      seatsByRow[row]!.add(seat);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Seats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.green),
                        const Text(' Available'),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.orange),
                        const Text(' Extra Legroom'),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.grey),
                        const Text(' Unavailable'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Number of passengers: '),
                    DropdownButton<int>(
                      value: _passengerCount,
                      items: [1, 2, 3, 4, 5, 6].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _passengerCount = value ?? 1;
                          if (_selectedSeats.length > _passengerCount) {
                            _selectedSeats = _selectedSeats.take(_passengerCount).toList();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: ${_selectedSeats.length}/$_passengerCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: seatsByRow.length,
              itemBuilder: (context, index) {
                final row = seatsByRow.keys.elementAt(index);
                final rowSeats = seatsByRow[row]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('Row $row', style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        child: Wrap(
                          children: rowSeats.map((seat) => _buildSeatWidget(seat)).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedSeats.length == _passengerCount
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            flightId: widget.flightId,
                            flight: widget.flight,
                            selectedSeats: _selectedSeats,
                            passengerCount: _passengerCount,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Continue to Booking'),
            ),
          ),
        ],
      ),
    );
  }
}

