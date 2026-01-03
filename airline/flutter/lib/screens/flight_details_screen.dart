import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'seat_selection_screen.dart';

class FlightDetailsScreen extends StatefulWidget {
  final int flightId;

  const FlightDetailsScreen({super.key, required this.flightId});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _flight;
  Map<String, dynamic>? _seatMap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlightDetails();
  }

  Future<void> _loadFlightDetails() async {
    try {
      final flight = await _api.getFlight(widget.flightId);
      final seatMap = await _api.getSeatMap(widget.flightId);
      setState(() {
        _flight = flight;
        _seatMap = seatMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flight details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_flight == null) {
      return const Scaffold(
        body: Center(child: Text('Flight not found')),
      );
    }

    final departureTime = DateTime.parse(_flight!['departure_time']);
    final arrivalTime = DateTime.parse(_flight!['arrival_time']);
    final duration = arrivalTime.difference(departureTime);

    return Scaffold(
      appBar: AppBar(title: Text(_flight!['flight_number'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_flight!['origin']['code']} → ${_flight!['destination']['code']}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${_flight!['origin']['name']} → ${_flight!['destination']['name']}'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Departure', style: Theme.of(context).textTheme.titleSmall),
                            Text(DateFormat('HH:mm').format(departureTime)),
                            Text(DateFormat('MMM dd, yyyy').format(departureTime)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('${duration.inHours}h ${duration.inMinutes % 60}m'),
                            const Icon(Icons.flight),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Arrival', style: Theme.of(context).textTheme.titleSmall),
                            Text(DateFormat('HH:mm').format(arrivalTime)),
                            Text(DateFormat('MMM dd, yyyy').format(arrivalTime)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Text('Price: \$${_flight!['base_price']}'),
                    Text('Available seats: ${_flight!['available_seats'] ?? 'N/A'}'),
                    Text('Status: ${_flight!['status']}'),
                    if (_flight!['gate'] != null) Text('Gate: ${_flight!['gate']}'),
                    if (_flight!['terminal'] != null) Text('Terminal: ${_flight!['terminal']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_seatMap != null) ...[
              Text(
                'Seat Map',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${_seatMap!['available_count']} / ${_seatMap!['total_count']}',
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatSelectionScreen(
                      flightId: widget.flightId,
                      flight: _flight!,
                    ),
                  ),
                );
              },
              child: const Text('Select Seats & Book'),
            ),
          ],
        ),
      ),
    );
  }
}

