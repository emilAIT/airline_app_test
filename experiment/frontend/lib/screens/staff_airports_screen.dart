import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/staff_service.dart';
import '../models/aviation.dart';
import 'staff_main_screen.dart';
import '../core/theme/app_theme.dart';

class StaffAirportsScreen extends ConsumerStatefulWidget {
  const StaffAirportsScreen({super.key});

  @override
  ConsumerState<StaffAirportsScreen> createState() => _StaffAirportsScreenState();
}

class _StaffAirportsScreenState extends ConsumerState<StaffAirportsScreen> {
  List<Airport> _airports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final airports = await staffService.getAirports();
      setState(() {
        _airports = airports;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAirport(Airport airport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete airport ${airport.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(staffServiceProvider).deleteAirport(airport.code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Airport deleted successfully')),
          );
          _loadAirports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
          },
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAirportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAirports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAirports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _airports.isEmpty
                  ? const Center(child: Text('No airports found'))
                  : ListView.builder(
                      itemCount: _airports.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final airport = _airports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(airport.code),
                            ),
                            title: Text(
                              airport.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${airport.city}, ${airport.country}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditAirportDialog(context, airport),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAirport(airport),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showCreateAirportDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Airport'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code (3 letters)',
                  hintText: 'JFK',
                  border: OutlineInputBorder(),
                ),
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'John F. Kennedy International Airport',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'New York',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  hintText: 'USA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              codeController.dispose();
              nameController.dispose();
              cityController.dispose();
              countryController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty ||
                  nameController.text.trim().isEmpty ||
                  cityController.text.trim().isEmpty ||
                  countryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final staffService = ref.read(staffServiceProvider);
                await staffService.createAirport(
                  code: codeController.text.trim().toUpperCase(),
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                  country: countryController.text.trim(),
                );
                
                codeController.dispose();
                nameController.dispose();
                cityController.dispose();
                countryController.dispose();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAirports();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Airport created successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditAirportDialog(BuildContext context, Airport airport) {
    final nameController = TextEditingController(text: airport.name);
    final cityController = TextEditingController(text: airport.city);
    final countryController = TextEditingController(text: airport.country);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Airport ${airport.code}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code: ${airport.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              cityController.dispose();
              countryController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  cityController.text.trim().isEmpty ||
                  countryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final staffService = ref.read(staffServiceProvider);
                await staffService.updateAirport(
                  code: airport.code,
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                  country: countryController.text.trim(),
                );
                
                nameController.dispose();
                cityController.dispose();
                countryController.dispose();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAirports();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Airport updated successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
