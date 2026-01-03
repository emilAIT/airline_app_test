import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'flight_details_screen.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _airports = [];
  dynamic _selectedOrigin;
  dynamic _selectedDestination;
  DateTime? _selectedDate;
  List<dynamic> _flights = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  bool _airportsLoaded = false;
  late final TextEditingController _dateController;
  int _formKeyIndex = 0;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _loadAirports();
    _searchFlights(); // Load all flights initially
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _resetSearch() async {
    print('DEBUG: Resetting search filters');
    setState(() {
      _selectedOrigin = null;
      _selectedDestination = null;
      _selectedDate = null;
      _dateController.text = '';
      _formKeyIndex++;
    });
    print('DEBUG: Search parameters after reset - Origin: $_selectedOrigin, Destination: $_selectedDestination, Date: $_selectedDate');
    await _searchFlights();
  }

  Future<void> _loadAirports() async {
    // ... (keep existing _loadAirports implementation)
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getAirports();
      
      if (mounted) {
        setState(() {
          _airports = List<dynamic>.from(response.data);
          _isLoading = false; // Note: _searchFlights also controls _isLoading/_isSearching, might conflict slightly but OK.
          _airportsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load airports. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchFlights() async {
    // if (!_formKey.currentState!.validate()) return; // Validation removed
    
    print('DEBUG: Searching flights - Origin: ${_selectedOrigin?['code']}, Destination: ${_selectedDestination?['code']}, Date: ${_selectedDate}');
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.searchFlights(
        originAirportId: _selectedOrigin?['id'],
        destinationAirportId: _selectedDestination?['id'],
        departureDate: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
      );

      if (mounted) {
        print('DEBUG: Search results - Found ${response.data.length} flights');
        setState(() {
          _flights = List<dynamic>.from(response.data);
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to search flights. Please try again.';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: ValueKey('form_$_formKeyIndex'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Search Flights',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<dynamic>(
                      isExpanded: true,
                      key: ValueKey('origin_${_selectedOrigin?['id']}'),
                      value: _selectedOrigin,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        prefixIcon: Icon(Icons.flight_takeoff),
                        border: OutlineInputBorder(),
                      ),
                      items: _airports.map((airport) {
                        return DropdownMenuItem(
                          value: airport,
                          child: Text(
                            '${airport['code']} - ${airport['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOrigin = value;
                        });
                      },
                      // validator: (value) => null, // Optional
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<dynamic>(
                      isExpanded: true,
                      key: ValueKey('destination_${_selectedDestination?['id']}'),
                      value: _selectedDestination,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        prefixIcon: Icon(Icons.flight_land),
                        border: OutlineInputBorder(),
                      ),
                      items: _airports.map((airport) {
                        return DropdownMenuItem(
                          value: airport,
                          child: Text(
                            '${airport['code']} - ${airport['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDestination = value;
                        });
                      },
                      // validator: (value) => null, // Optional
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey('date_${_selectedDate?.millisecondsSinceEpoch}'),
                      readOnly: true,
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Departure Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                        suffixIcon: _selectedDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = null;
                                    _dateController.text = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onTap: () => _selectDate(context),
                      // validator: (value) => null, // Optional
                    ),
                    const SizedBox(height: 24),
                    if (_isSearching)
                      const LoadingWidget(message: 'Searching flights...')
                    else
                      ElevatedButton.icon(
                        onPressed: _searchFlights,
                        icon: const Icon(Icons.search),
                        label: const Text('Search Flights'),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resetSearch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('See All Flights'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading && !_airportsLoaded && _flights.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: LoadingWidget(message: 'Loading airports...'),
              )
            else if (_errorMessage != null && !_airportsLoaded && _flights.isEmpty)
              ErrorDisplayWidget(
                message: _errorMessage!,
                onRetry: _loadAirports,
              )
            else if (_flights.isEmpty && _isSearching == false)
              const EmptyStateWidget(
                title: 'No flights found',
                message: 'Search for flights using the form above',
                icon: Icons.flight,
              )
            else if (_flights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final now = DateTime.now().toUtc();
                  final filteredFlights = _flights.where((flight) {
                    final status = flight['status'].toString().toUpperCase();
                    if (status == 'CANCELLED' || status == 'LANDED') return false;
                    
                    final departureTime = DateTime.parse(flight['departure_time']);
                    // Show flights that are upcoming or at most 2 hours in the past (to account for boarding/delays)
                    return departureTime.isAfter(now.subtract(const Duration(hours: 2)));
                  }).toList()
                    ..sort((a, b) => DateTime.parse(a['departure_time']).compareTo(DateTime.parse(b['departure_time'])));

                  if (filteredFlights.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No upcoming flights',
                      message: 'Check back later for new scheduled flights',
                      icon: Icons.flight,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Upcoming Flights (${filteredFlights.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Booking is available until 1 hour before departure.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filteredFlights.map((flight) => _buildFlightCard(flight)),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlightCard(dynamic flight) {
    final departureTime = DateTime.parse(flight['departure_time']);
    final arrivalTime = DateTime.parse(flight['arrival_time']);
    final duration = arrivalTime.difference(departureTime);
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;
    
    final bool canBook = (flight['status'] == 'SCHEDULED' || flight['status'] == 'DELAYED') &&
        departureTime.difference(DateTime.now().toUtc()).inMinutes > 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: canBook ? null : Colors.grey.shade50,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlightDetailsScreen(flightId: flight['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    flight['flight_number'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text(flight['status']),
                    backgroundColor: _getStatusColor(flight['status']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(departureTime),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          DateFormat('MMM dd').format(departureTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${durationHours}h ${durationMinutes}m',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Icon(Icons.flight, size: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(arrivalTime),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          DateFormat('MMM dd').format(arrivalTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${flight['price'].toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: canBook ? Theme.of(context).colorScheme.primary : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (!canBook)
                        Text(
                          'Booking Closed',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FlightDetailsScreen(flightId: flight['id']),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return Colors.blue.shade100;
      case 'BOARDING':
        return Colors.orange.shade100;
      case 'DELAYED':
        return Colors.red.shade100;
      case 'CANCELLED':
        return Colors.grey.shade300;
      case 'DEPARTED':
        return Colors.purple.shade100;
      case 'LANDED':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}

