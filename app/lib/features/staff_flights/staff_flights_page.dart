import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/flight.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class StaffFlightsPage extends StatefulWidget {
  const StaffFlightsPage({super.key});

  @override
  State<StaffFlightsPage> createState() => _StaffFlightsPageState();
}

class _StaffFlightsPageState extends State<StaffFlightsPage> {
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
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
    _staffApi = StaffApi(_apiClient);
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flights = await _staffApi.getAllFlights();
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

  Future<void> _deleteFlight(int flightId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flight?'),
        content: const Text('Are you sure you want to delete this flight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    
    try {
      await _staffApi.deleteFlight(flightId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight deleted')),
        );
        _loadFlights();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Flights')),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadFlights)
              : _flights.isEmpty
                  ? const EmptyView(message: 'No flights found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flights.length,
                      itemBuilder: (context, index) {
                        final flight = _flights[index];
                        return Card(
                          child: ListTile(
                            title: Text(flight.flightNumber),
                            subtitle: Text('${flight.origin?.code} → ${flight.destination?.code}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.staffFlightEdit,
                                      arguments: flight.id,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFlight(flight.id),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.staffFlightEdit,
                                arguments: flight.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.staffFlightCreate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
