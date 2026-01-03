import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/airports_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/airport.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final AirportsApi _airportsApi;
  
  List<Airport> _airports = [];
  Airport? _originAirport;
  Airport? _destinationAirport;
  DateTime? _departureDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _airportsApi = AirportsApi(_apiClient);
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() => _isLoading = true);

    try {
      final airports = await _airportsApi.getAirports();
      setState(() {
        _airports = airports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load airports: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  void _searchFlights() {
    if (!_formKey.currentState!.validate()) return;

    if (_originAirport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select origin airport')),
      );
      return;
    }

    if (_destinationAirport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination airport')),
      );
      return;
    }

    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure date')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRouter.flightList,
      arguments: {
        'origin': _originAirport!.code,
        'destination': _destinationAirport!.code,
        'date': _departureDate!.toIso8601String().split('T')[0],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Flights')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flight Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Airport>(
                            decoration: const InputDecoration(
                              labelText: 'From',
                              prefixIcon: Icon(Icons.flight_takeoff),
                            ),
                            initialValue: _originAirport,
                            items: _airports.map((airport) {
                              return DropdownMenuItem(
                                value: airport,
                                child: Text('${airport.city} (${airport.code})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _originAirport = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Airport>(
                            decoration: const InputDecoration(
                              labelText: 'To',
                              prefixIcon: Icon(Icons.flight_land),
                            ),
                            initialValue: _destinationAirport,
                            items: _airports.map((airport) {
                              return DropdownMenuItem(
                                value: airport,
                                child: Text('${airport.city} (${airport.code})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _destinationAirport = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Departure Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _departureDate != null
                                    ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _departureDate != null ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _searchFlights,
                              icon: const Icon(Icons.search),
                              label: const Text('Search Flights'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
