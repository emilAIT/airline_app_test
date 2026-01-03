import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_flight_dialog.dart';
import 'admin_seat_map_screen.dart';

class AdminFlightsScreen extends StatefulWidget {
  const AdminFlightsScreen({super.key});

  @override
  State<AdminFlightsScreen> createState() => _AdminFlightsScreenState();
}

class _AdminFlightsScreenState extends State<AdminFlightsScreen> {
  List<dynamic> _flights = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getStaffFlights();
      
      if (mounted) {
        setState(() {
          _flights = List<dynamic>.from(response.data);
          // Sort by departure time descending
          _flights.sort((a, b) {
            final aTime = DateTime.parse(a['departure_time']);
            final bTime = DateTime.parse(b['departure_time']);
            return bTime.compareTo(aTime);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load flights';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFlights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _flights.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.flight,
                      title: 'No Flights',
                      message: 'Create your first flight to get started',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFlights,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _flights.length,
                        itemBuilder: (context, index) {
                          final flight = _flights[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.flight, size: 32),
                              title: Text(
                                flight['flight_number'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${flight['origin_airport']?['code'] ?? 'N/A'} → ${flight['destination_airport']?['code'] ?? 'N/A'}'),
                                  if (flight['departure_time'] != null)
                                    Text(
                                      DateFormat('MMM dd, yyyy HH:mm').format(
                                        DateTime.parse(flight['departure_time']),
                                      ),
                                    ),
                                  Text('Status: ${flight['status'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${flight['price']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.grid_view, color: Colors.green),
                                    tooltip: 'View Seat Map',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AdminSeatMapScreen(
                                            flightId: flight['id'],
                                            flightNumber: flight['flight_number'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await showDialog(
                                        context: context,
                                        builder: (context) => CreateFlightDialog(flight: flight),
                                      );
                                      if (result == true) {
                                        _loadFlights();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Flight'),
                                          content: Text('Are you sure you want to delete ${flight['flight_number']}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && mounted) {
                                        try {
                                          await Provider.of<ApiService>(context, listen: false)
                                              .deleteStaffFlight(flight['id']);
                                          _loadFlights();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Flight deleted successfully')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to delete flight: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Show flight details
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const CreateFlightDialog(),
          );
          if (result == true) {
            _loadFlights();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Flight'),
      ),
    );
  }
}

