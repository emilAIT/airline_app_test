import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_airport_dialog.dart';
import 'airport_flights_screen.dart';

class AdminAirportsScreen extends StatefulWidget {
  const AdminAirportsScreen({super.key});

  @override
  State<AdminAirportsScreen> createState() => _AdminAirportsScreenState();
}

class _AdminAirportsScreenState extends State<AdminAirportsScreen> {
  List<dynamic> _airports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load airports';
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
                        onPressed: _loadAirports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _airports.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.flight_takeoff,
                      title: 'No Airports',
                      message: 'Create your first airport to get started',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAirports,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            color: Theme.of(context).primaryColor.withOpacity(0.05),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Select an airport to view arriving and departing flights.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _airports.length,
                              itemBuilder: (context, index) {
                          final airport = _airports[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Text(
                                  airport['code'] ?? '???',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                airport['name'] ?? 'Unknown Airport',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${airport['city']}, ${airport['country']}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Airport'),
                                      content: Text('Are you sure you want to delete ${airport['name']}?'),
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
                                          .deleteAirport(airport['id']);
                                      _loadAirports();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Airport deleted successfully')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to delete airport: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AirportFlightsScreen(
                                      airportId: airport['id'],
                                      airportCode: airport['code'] ?? 'UNK',
                                      airportName: airport['name'] ?? 'Unknown Airport',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const CreateAirportDialog(),
          );
          if (result == true) {
            _loadAirports();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Airport'),
      ),
    );
  }
}
