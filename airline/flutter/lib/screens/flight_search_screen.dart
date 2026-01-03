import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'flight_details_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _airports = [];
  List<dynamic> _flights = [];
  bool _isLoading = false;
  bool _isSearching = false;

  int? _selectedOriginId;
  int? _selectedDestinationId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() => _isLoading = true);
    try {
      final airports = await _api.getAirports();
      print('FlightSearchScreen - Loaded ${airports.length} airports');
      if (airports.isNotEmpty) {
        print('First airport: ${airports[0]}');
      }
      setState(() {
        _airports = airports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading airports: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading airports: $e'),
            backgroundColor: EldiyarTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _searchFlights() async {
    if (_selectedOriginId == null || _selectedDestinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select origin and destination'),
          backgroundColor: EldiyarTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      // Date is optional - if not selected, search all dates
      String? dateStr;
      if (_selectedDate != null) {
        dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      final flights = await _api.getFlights(
        originId: _selectedOriginId,
        destinationId: _selectedDestinationId,
        departureDate: dateStr,
      );
      setState(() {
        _flights = flights;
        _isSearching = false;
      });

      if (flights.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedDate != null
                  ? 'No flights found for the selected route and date'
                  : 'No flights found for the selected route',
            ),
            backgroundColor: EldiyarTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching flights: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EldiyarTheme.primaryBlue,
              onPrimary: EldiyarTheme.darkerBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      EldiyarTheme.primaryBlue,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: EldiyarTheme.primaryBlue,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Search Flights',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: EldiyarTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.flight_takeoff,
                                    color: EldiyarTheme.primaryBlue,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedOriginId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Origin *',
                                      hintText: _airports.isEmpty
                                          ? 'Loading airports...'
                                          : 'Select origin airport',
                                      prefixIcon: const Icon(
                                        Icons.location_on,
                                        color: EldiyarTheme.primaryBlue,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                    dropdownColor: EldiyarTheme.cardBackground,
                                    items: _airports.isEmpty
                                        ? [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              enabled: false,
                                              child: Text(
                                                'No airports available',
                                                style: TextStyle(
                                                  color: EldiyarTheme
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : _airports.map<DropdownMenuItem<int>>((
                                            airport,
                                          ) {
                                            final airportId =
                                                airport['id'] is int
                                                ? airport['id']
                                                : int.tryParse(
                                                    airport['id'].toString(),
                                                  );
                                            return DropdownMenuItem<int>(
                                              value: airportId,
                                              child: Text(
                                                '${airport['code']} - ${airport['name']}',
                                                style: const TextStyle(
                                                  color:
                                                      EldiyarTheme.textPrimary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    onChanged: _airports.isEmpty
                                        ? null
                                        : (value) => setState(
                                            () => _selectedOriginId = value,
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedDestinationId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Destination *',
                                      hintText: _airports.isEmpty
                                          ? 'Loading airports...'
                                          : 'Select destination airport',
                                      prefixIcon: const Icon(
                                        Icons.location_on,
                                        color: EldiyarTheme.primaryBlue,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                    dropdownColor: EldiyarTheme.cardBackground,
                                    items: _airports.isEmpty
                                        ? [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              enabled: false,
                                              child: Text(
                                                'No airports available',
                                                style: TextStyle(
                                                  color: EldiyarTheme
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : _airports.map<DropdownMenuItem<int>>((
                                            airport,
                                          ) {
                                            final airportId =
                                                airport['id'] is int
                                                ? airport['id']
                                                : int.tryParse(
                                                    airport['id'].toString(),
                                                  );
                                            return DropdownMenuItem<int>(
                                              value: airportId,
                                              child: Text(
                                                '${airport['code']} - ${airport['name']}',
                                                style: const TextStyle(
                                                  color:
                                                      EldiyarTheme.textPrimary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    onChanged: _airports.isEmpty
                                        ? null
                                        : (value) => setState(
                                            () =>
                                                _selectedDestinationId = value,
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Departure Date (optional)',
                                        prefixIcon: Icon(
                                          Icons.calendar_today,
                                          color: EldiyarTheme.primaryBlue,
                                        ),
                                      ),
                                      child: Text(
                                        _selectedDate == null
                                            ? 'Select date (optional)'
                                            : DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(_selectedDate!),
                                        style: const TextStyle(
                                          color: EldiyarTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GlowButton(
                                    label: 'Search Flights',
                                    icon: Icons.search,
                                    onPressed: _isSearching
                                        ? null
                                        : _searchFlights,
                                    isLoading: _isSearching,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Results
                            if (_flights.isEmpty && _isSearching == false)
                              const Center(
                                child: Text(
                                  'No flights found. Try a different search.',
                                  style: TextStyle(
                                    color: EldiyarTheme.textSecondary,
                                  ),
                                ),
                              )
                            else if (_flights.isNotEmpty)
                              ..._flights.map((flight) {
                                final departureTime = DateTime.parse(
                                  flight['departure_time'],
                                );
                                final arrivalTime = DateTime.parse(
                                  flight['arrival_time'],
                                );

                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FlightDetailsScreen(
                                              flightId: flight['id'],
                                            ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            flight['flight_number'],
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: EldiyarTheme.primaryBlue,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: EldiyarTheme.primaryBlue
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: EldiyarTheme.primaryBlue
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: Text(
                                              '\$${flight['base_price']}',
                                              style: const TextStyle(
                                                color: EldiyarTheme.primaryBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                flight['origin']['code'],
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      EldiyarTheme.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'HH:mm',
                                                ).format(departureTime),
                                                style: const TextStyle(
                                                  color: EldiyarTheme
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: EldiyarTheme.primaryBlue,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                flight['destination']['code'],
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      EldiyarTheme.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'HH:mm',
                                                ).format(arrivalTime),
                                                style: const TextStyle(
                                                  color: EldiyarTheme
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Available: ${flight['available_seats'] ?? 'N/A'} seats',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                flight['status'],
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              flight['status'],
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  flight['status'],
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
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
        return EldiyarTheme.primaryBlue;
      case 'BOARDING':
        return EldiyarTheme.accentTeal;
      case 'DELAYED':
        return Colors.orange;
      case 'CANCELLED':
        return EldiyarTheme.errorRed;
      case 'DEPARTED':
        return EldiyarTheme.textSecondary;
      case 'LANDED':
        return EldiyarTheme.successGreen;
      default:
        return EldiyarTheme.textSecondary;
    }
  }
}
