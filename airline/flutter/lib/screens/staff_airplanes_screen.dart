import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class StaffAirplanesScreen extends StatefulWidget {
  const StaffAirplanesScreen({super.key});

  @override
  State<StaffAirplanesScreen> createState() => _StaffAirplanesScreenState();
}

class _StaffAirplanesScreenState extends State<StaffAirplanesScreen> {
  final ApiService _api = ApiService();
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
      final airplanes = await _api.getStaffAirplanes();
      setState(() {
        _airplanes = airplanes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading airplanes: $e'),
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
                        'Manage Airplanes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: EldiyarTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: EldiyarTheme.primaryBlue,
                        size: 32,
                      ),
                      onPressed: () => _showCreateDialog(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : _airplanes.isEmpty
                    ? const Center(
                        child: Text(
                          'No airplanes found',
                          style: TextStyle(color: EldiyarTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: EldiyarTheme.primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _airplanes.length,
                          itemBuilder: (context, index) {
                            final airplane = _airplanes[index];
                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: EldiyarTheme.accentTeal
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: EldiyarTheme.accentTeal
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.airplanemode_active,
                                      color: EldiyarTheme.accentTeal,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          airplane['model'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: EldiyarTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${airplane['total_seats']} seats',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: EldiyarTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
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

  void _showCreateDialog(BuildContext context) {
    final modelController = TextEditingController();
    final totalSeatsController = TextEditingController();
    final rowsController = TextEditingController();
    final seatsPerRowController = TextEditingController();
    final extraLegroomRowsController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: EldiyarTheme.cardBackground,
          title: const Text(
            'Create Airplane',
            style: TextStyle(color: EldiyarTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'e.g., Boeing 737-800',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalSeatsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats',
                    hintText: 'e.g., 180',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Rows',
                    hintText: 'e.g., 30',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: seatsPerRowController,
                  decoration: const InputDecoration(
                    labelText: 'Seats per Row (comma-separated)',
                    hintText: 'e.g., 3,3 (for 3-3 configuration)',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: extraLegroomRowsController,
                  decoration: const InputDecoration(
                    labelText: 'Extra Legroom Rows (comma-separated, optional)',
                    hintText: 'e.g., 1,2,3',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EldiyarTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (modelController.text.isEmpty ||
                          totalSeatsController.text.isEmpty ||
                          rowsController.text.isEmpty ||
                          seatsPerRowController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill required fields'),
                            backgroundColor: EldiyarTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      try {
                        // Parse seats per row
                        final seatsPerRowList = seatsPerRowController.text
                            .split(',')
                            .map((s) => int.tryParse(s.trim()))
                            .where((v) => v != null)
                            .cast<int>()
                            .toList();

                        if (seatsPerRowList.isEmpty) {
                          throw Exception('Invalid seats per row format');
                        }

                        // Parse extra legroom rows if provided
                        List<int>? extraLegroomRows;
                        if (extraLegroomRowsController.text.isNotEmpty) {
                          extraLegroomRows = extraLegroomRowsController.text
                              .split(',')
                              .map((s) => int.tryParse(s.trim()))
                              .where((v) => v != null)
                              .cast<int>()
                              .toList();
                        }

                        setDialogState(() => isSubmitting = true);
                        
                        // Safe parsing with validation
                        final totalSeats = int.tryParse(totalSeatsController.text.trim());
                        final rows = int.tryParse(rowsController.text.trim());
                        
                        if (totalSeats == null || rows == null) {
                          throw Exception('Total seats and rows must be valid numbers');
                        }
                        
                        await _api.createAirplane({
                          'model': modelController.text,
                          'total_seats': totalSeats,
                          'seat_config': {
                            'rows': rows,
                            'seats_per_row': seatsPerRowList,
                            if (extraLegroomRows != null)
                              'extra_legroom_rows': extraLegroomRows,
                          },
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Airplane created successfully!'),
                              backgroundColor: EldiyarTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: EldiyarTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: EldiyarTheme.primaryBlue.withOpacity(0.2),
                foregroundColor: EldiyarTheme.primaryBlue,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          EldiyarTheme.primaryBlue,
                        ),
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
