import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_airplane_dialog.dart';

class AdminAirplanesScreen extends StatefulWidget {
  const AdminAirplanesScreen({super.key});

  @override
  State<AdminAirplanesScreen> createState() => _AdminAirplanesScreenState();
}

class _AdminAirplanesScreenState extends State<AdminAirplanesScreen> {
  List<dynamic> _airplanes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAirplanes();
  }

  Future<void> _loadAirplanes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getStaffAirplanes();
      
      if (mounted) {
        setState(() {
          _airplanes = List<dynamic>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load airplanes: $e';
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
                        onPressed: _loadAirplanes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _airplanes.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.airplanemode_active,
                      title: 'No Airplanes',
                      message: 'Create your first airplane to get started',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAirplanes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _airplanes.length,
                        itemBuilder: (context, index) {
                          final airplane = _airplanes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.airplanemode_active, size: 32),
                              title: Text(
                                airplane['model'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Registration: ${airplane['registration_number'] ?? 'N/A'}\n'
                                'Capacity: ${airplane['capacity'] ?? 'N/A'} seats\n'
                                'Status: ${airplane['status'] ?? 'ACTIVE'}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await showDialog(
                                        context: context,
                                        builder: (context) => CreateAirplaneDialog(airplane: airplane),
                                      );
                                      if (result == true) {
                                        _loadAirplanes();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Airplane'),
                                          content: Text('Are you sure you want to delete ${airplane['model']}?'),
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
                                              .deleteStaffAirplane(airplane['id']);
                                          _loadAirplanes();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Airplane deleted successfully')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to delete airplane: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Optional: Show detailed view
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
            builder: (context) => const CreateAirplaneDialog(),
          );
          if (result == true) {
            _loadAirplanes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Airplane'),
      ),
    );
  }
}

