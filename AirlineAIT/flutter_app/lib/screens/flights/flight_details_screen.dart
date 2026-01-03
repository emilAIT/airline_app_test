import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../bookings/create_booking_screen.dart';

class FlightDetailsScreen extends StatefulWidget {
  final int flightId;

  const FlightDetailsScreen({super.key, required this.flightId});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  dynamic _flight;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlightDetails();
  }

  Future<void> _loadFlightDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final flightResponse = await apiService.getFlightDetails(widget.flightId);

      if (mounted) {
        setState(() {
          _flight = flightResponse.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load flight details';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flight Details')),
        body: const LoadingWidget(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flight Details')),
        body: ErrorDisplayWidget(
          message: _errorMessage!,
          onRetry: _loadFlightDetails,
        ),
      );
    }

    if (_flight == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flight Details')),
        body: const Center(child: Text('Flight not found')),
      );
    }

    final departureTime = DateTime.parse(_flight['departure_time']);
    final arrivalTime = DateTime.parse(_flight['arrival_time']);
    final duration = arrivalTime.difference(departureTime);
    
    final bool canBook = (_flight['status'] == 'SCHEDULED' || _flight['status'] == 'DELAYED') &&
        departureTime.difference(DateTime.now().toUtc()).inMinutes > 60;

    return Scaffold(
      appBar: AppBar(title: Text(_flight['flight_number'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _flight['flight_number'],
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Chip(
                          label: Text(_flight['status']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _flight['origin_airport']['code'],
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _flight['origin_airport']['name'],
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                DateFormat('HH:mm').format(departureTime),
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Text(
                                '${duration.inHours}h ${duration.inMinutes % 60}m',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Icon(Icons.flight, size: 24),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _flight['destination_airport']['code'],
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _flight['destination_airport']['name'],
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                DateFormat('HH:mm').format(arrivalTime),
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gate',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _flight['gate'] ?? 'TBA',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Terminal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _flight['terminal'] ?? 'TBA',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Price',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '\$${_flight['price'].toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_flight['available_seats'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_flight['available_seats']} seats available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!canBook)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _flight['status'] == 'CANCELLED' 
                          ? 'This flight has been cancelled.' 
                          : 'Booking is closed for this flight. Online booking ends 1 hour before departure.',
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateBookingScreen(flightId: widget.flightId),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Book Flight'),
              ),
          ],
        ),
      ),
    );
  }
}

