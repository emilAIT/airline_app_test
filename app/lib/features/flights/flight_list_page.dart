import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/flights_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/flight.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/flight_card.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class FlightListPage extends StatefulWidget {
  final Map<String, dynamic> searchParams;

  const FlightListPage({super.key, required this.searchParams});

  @override
  State<FlightListPage> createState() => _FlightListPageState();
}

class _FlightListPageState extends State<FlightListPage> {
  late final ApiClient _apiClient;
  late final FlightsApi _flightsApi;
  List<Flight> _flights = [];
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
    _searchFlights();
  }

  Future<void> _searchFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flights = await _flightsApi.searchFlights(
        origin: widget.searchParams['origin'],
        destination: widget.searchParams['destination'],
        departureDate: widget.searchParams['date'],
      );
      setState(() {
        _flights = flights;
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
        title: const Text('Available Flights'),
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _searchFlights)
              : _flights.isEmpty
                  ? const EmptyView(message: 'No flights found for this route')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flights.length,
                      itemBuilder: (context, index) {
                        final flight = _flights[index];
                        return FlightCard(
                          flight: flight,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.flightDetails,
                              arguments: flight.id,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
