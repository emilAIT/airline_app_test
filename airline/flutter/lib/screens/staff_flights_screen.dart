import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';
import 'create_flight_screen.dart';
import 'edit_flight_screen.dart';

class StaffFlightsScreen extends StatefulWidget {
  const StaffFlightsScreen({super.key});

  @override
  State<StaffFlightsScreen> createState() => _StaffFlightsScreenState();
}

class _StaffFlightsScreenState extends State<StaffFlightsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _flights = [];
  List<dynamic> _airports = [];
  List<dynamic> _airplanes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final flights = await _api.getStaffFlights();
      final airports = await _api.getStaffAirports();
      final airplanes = await _api.getStaffAirplanes();
      setState(() {
        _flights = flights;
        _airports = airports;
        _airplanes = airplanes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
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
          child: Column(
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
                        'Manage Flights',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: EldiyarTheme.textPrimary,
                        ),
                      ),
                    ),
                    GlowButton(
                      label: 'Add Flight',
                      icon: Icons.add,
                      onPressed: () async {
                        // Reload airports and airplanes before opening create screen
                        try {
                          final airports = await _api.getStaffAirports();
                          final airplanes = await _api.getStaffAirplanes();

                          if (airports.isEmpty || airplanes.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    airports.isEmpty && airplanes.isEmpty
                                        ? 'Please add airports and airplanes first from Staff Dashboard'
                                        : airports.isEmpty
                                        ? 'Please add airports first from Staff Dashboard'
                                        : 'Please add airplanes first from Staff Dashboard',
                                  ),
                                  backgroundColor: EldiyarTheme.errorRed,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateFlightScreen(
                                airports: airports,
                                airplanes: airplanes,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error loading data: $e'),
                                backgroundColor: EldiyarTheme.errorRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Flights List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : _flights.isEmpty
                    ? const Center(
                        child: Text(
                          'No flights found',
                          style: TextStyle(color: EldiyarTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _flights.length,
                          itemBuilder: (context, index) {
                            final flight = _flights[index];
                            final departureTime = DateTime.parse(
                              flight['departure_time'],
                            );
                            final arrivalTime = DateTime.parse(
                              flight['arrival_time'],
                            );

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditFlightScreen(
                                      flight: flight,
                                      airports: _airports,
                                      airplanes: _airplanes,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          flight['flight_number'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: EldiyarTheme.primaryBlue,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              flight['status'],
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                flight['status'],
                                              ).withOpacity(0.5),
                                            ),
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              flight['origin']['code'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: EldiyarTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              flight['origin']['name'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: EldiyarTheme.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM dd, HH:mm',
                                              ).format(departureTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: EldiyarTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          color: EldiyarTheme.primaryBlue,
                                          size: 20,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              flight['destination']['code'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: EldiyarTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              flight['destination']['name'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: EldiyarTheme.textSecondary,
                                              ),
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM dd, HH:mm',
                                              ).format(arrivalTime),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: EldiyarTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Price: \$${flight['base_price']}',
                                          style: const TextStyle(
                                            color: EldiyarTheme.accentTeal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (flight['gate'] != null)
                                        Flexible(
                                          child: Text(
                                            'Gate: ${flight['gate']}',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      if (flight['terminal'] != null) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Terminal: ${flight['terminal']}',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
