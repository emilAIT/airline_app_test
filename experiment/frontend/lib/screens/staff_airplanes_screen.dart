import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../services/staff_service.dart';
import '../models/aviation.dart';
import '../core/theme/app_theme.dart';
import 'staff_main_screen.dart';

class StaffAirplanesScreen extends ConsumerStatefulWidget {
  const StaffAirplanesScreen({super.key});

  @override
  ConsumerState<StaffAirplanesScreen> createState() => _StaffAirplanesScreenState();
}

class _StaffAirplanesScreenState extends ConsumerState<StaffAirplanesScreen> {
  List<Airplane> _airplanes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAirplanes();
  }

  Future<void> _loadAirplanes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final airplanes = await staffService.getAirplanes();
      setState(() {
        _airplanes = airplanes;
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

  Future<void> _deleteAirplane(Airplane airplane) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete airplane ${airplane.name}?'),
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
        await ref.read(staffServiceProvider).deleteAirplane(airplane.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Airplane deleted successfully')),
          );
          _loadAirplanes();
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Airplanes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
              ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppTheme.primaryColor),
            onPressed: () => _showCreateAirplaneDialog(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw, color: Colors.white),
            onPressed: _loadAirplanes,
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
                      Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAirplanes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _airplanes.isEmpty
                  ? const Center(
                      child: Text(
                        'No airplanes found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _airplanes.length,
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final airplane = _airplanes[index];
                        return Card(
                          color: AppTheme.surfaceColor,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          airplane.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          airplane.model,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(LucideIcons.plane, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildInfoChip(LucideIcons.armchair, '${airplane.seats.length} Seats'),
                                    const SizedBox(width: 12),
                                    // Calculate business/economy split if possible, or just show total seats
                                    // For now just showing total seats as per model
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFF334155)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.eye, color: AppTheme.textSecondary),
                                      onPressed: () => _showSeats(context, airplane),
                                      tooltip: 'View Seats',
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit2, color: AppTheme.primaryColor),
                                      onPressed: () => _showEditAirplaneDialog(context, airplane),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: AppTheme.errorColor),
                                      onPressed: () => _deleteAirplane(airplane),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAirplaneDialog(BuildContext context) {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final rowsController = TextEditingController();
    final seatsPerRowController = TextEditingController();
    final businessRowsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Create Airplane', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'B777-001',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'Boeing 777',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rowsController,
                 style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Number of Rows',
                  hintText: '30',
                   labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: seatsPerRowController,
                 style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Seats per Row',
                  hintText: '6',
                   labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: businessRowsController,
                 style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Extra Leg Room Rows',
                  hintText: '5',
                   labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              modelController.dispose();
              rowsController.dispose();
              seatsPerRowController.dispose();
              businessRowsController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              try {
                final rows = int.tryParse(rowsController.text.trim());
                final seatsPerRow = int.tryParse(seatsPerRowController.text.trim());
                final businessRows = int.tryParse(businessRowsController.text.trim());

                if (nameController.text.trim().isEmpty ||
                    modelController.text.trim().isEmpty ||
                    rows == null ||
                    seatsPerRow == null ||
                    businessRows == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields with valid numbers')),
                  );
                  return;
                }

                final staffService = ref.read(staffServiceProvider);
                await staffService.createAirplane(
                  name: nameController.text.trim(),
                  model: modelController.text.trim(),
                  rows: rows,
                  seatsPerRow: seatsPerRow,
                  businessRows: businessRows,
                );
                
                nameController.dispose();
                modelController.dispose();
                rowsController.dispose();
                seatsPerRowController.dispose();
                businessRowsController.dispose();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAirplanes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Airplane created successfully!')),
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

  void _showSeats(BuildContext context, Airplane airplane) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('${airplane.name} Seats', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total seats: ${airplane.seats.length}', style: const TextStyle(color: AppTheme.textPrimary)),
                // Could visualize seat map here if data structure supported it easily
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditAirplaneDialog(BuildContext context, Airplane airplane) {
    final nameController = TextEditingController(text: airplane.name);
    final modelController = TextEditingController(text: airplane.model);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Edit Airplane ${airplane.name}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${airplane.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              Text('Seats: ${airplane.seats.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                 style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                 style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Model',
                   labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              modelController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  modelController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final staffService = ref.read(staffServiceProvider);
                await staffService.updateAirplane(
                  airplaneId: airplane.id,
                  name: nameController.text.trim(),
                  model: modelController.text.trim(),
                );
                
                nameController.dispose();
                modelController.dispose();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadAirplanes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Airplane updated successfully!')),
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
