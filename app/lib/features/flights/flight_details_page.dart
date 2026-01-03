import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/flights_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/flight.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';
import '../../app/router.dart';

class FlightDetailsPage extends StatefulWidget {
  final int flightId;

  const FlightDetailsPage({super.key, required this.flightId});

  @override
  State<FlightDetailsPage> createState() => _FlightDetailsPageState();
}

class _FlightDetailsPageState extends State<FlightDetailsPage> {
  late final ApiClient _apiClient;
  late final FlightsApi _flightsApi;
  Flight? _flight;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _flightsApi = FlightsApi(_apiClient);
    _loadFlightDetails();
  }

  Future<void> _loadFlightDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flight = await _flightsApi.getFlight(widget.flightId);
      setState(() {
        _flight = flight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_seat),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.seatMap,
                arguments: widget.flightId,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadFlightDetails)
              : _flight == null
                  ? const Center(child: Text('No data'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final flight = _flight!;
    
    return SingleChildScrollView(
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
                  Row(
                    children: [
                      Icon(Icons.flight_takeoff, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        flight.flightNumber,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(flight.status.name),
                        backgroundColor: _getStatusColor(flight.status),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Origin', flight.origin?.city ?? 'N/A'),
                  _buildInfoRow('Destination', flight.destination?.city ?? 'N/A'),
                  _buildInfoRow('Departure', Formatters.formatDateTime(flight.departureTime)),
                  _buildInfoRow('Arrival', Formatters.formatDateTime(flight.arrivalTime)),
                  _buildInfoRow('Duration', flight.durationMinutes != null ? '${flight.durationMinutes} minutes' : 'N/A'),
                  if (flight.gate != null)
                    _buildInfoRow('Gate', flight.gate!),
                  if (flight.terminal != null)
                    _buildInfoRow('Terminal', flight.terminal!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing & Availability',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Price', '\$${flight.basePrice.toStringAsFixed(2)}'),
                  _buildInfoRow('Available Seats', '${flight.availableSeats}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Book This Flight',
            onPressed: (flight.availableSeats ?? 0) > 0
                ? () {
                    Navigator.of(context).pushNamed(
                      AppRouter.passengerInfo,
                      arguments: flight.id,
                    );
                  }
                : null,
            icon: Icons.book_online,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last;
    switch (statusStr) {
      case 'SCHEDULED':
      case 'BOARDING':
        return Colors.green;
      case 'DELAYED':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
