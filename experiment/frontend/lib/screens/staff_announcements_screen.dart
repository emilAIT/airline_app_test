import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/flight.dart';
import '../services/staff_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../services/flight_service.dart';
import 'staff_main_screen.dart';
import 'package:dio/dio.dart';

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

class StaffAnnouncementsScreen extends ConsumerStatefulWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  ConsumerState<StaffAnnouncementsScreen> createState() => _StaffAnnouncementsScreenState();
}

class _StaffAnnouncementsScreenState extends ConsumerState<StaffAnnouncementsScreen> {
  List<Flight> _flights = [];
  List<Announcement> _allAnnouncements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        throw Exception('Not authenticated');
      }

      final flightService = ref.read(flightServiceProvider);
      final flights = await flightService.getAllFlights();

      // Collect all announcements from all flights
      List<Announcement> allAnnouncements = [];
      for (var flight in flights) {
        try {
          final announcements = await flightService.getFlightAnnouncements(
            flight.id,
            token: authState.token,
          );
          allAnnouncements.addAll(announcements);
        } catch (e) {
          // Skip flights without announcements
        }
      }

      // Sort announcements by creation date (newest first)
      allAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _flights = flights;
          _allAnnouncements = allAnnouncements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateAnnouncementDialog() async {
    if (_flights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flights available. Create a flight first.')),
      );
      return;
    }

    final flightController = TextEditingController();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'General Info';
    Flight? selectedFlight;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Flight>(
                  decoration: const InputDecoration(labelText: 'Flight'),
                  items: _flights.map((flight) {
                    return DropdownMenuItem<Flight>(
                      value: flight,
                      child: Text('${flight.flightNumber} - ${flight.departureAirportCode} → ${flight.arrivalAirportCode}'),
                    );
                  }).toList(),
                  onChanged: (Flight? flight) {
                    setDialogState(() {
                      selectedFlight = flight;
                      flightController.text = flight?.flightNumber ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: <String>[
                    'Delay',
                    'Cancellation',
                    'Gate Change',
                    'Boarding Started',
                    'General Info'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setDialogState(() {
                      selectedType = value ?? 'General Info';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedFlight == null || titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  final authState = ref.read(authProvider);
                  if (authState.token == null) {
                    throw Exception('Not authenticated');
                  }

                  final staffService = ref.read(staffServiceProvider);
                  await staffService.createAnnouncement(
                    flightId: selectedFlight!.id,
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    type: selectedType,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Reload data to show the new announcement
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Announcement created successfully!'),
                        backgroundColor: Colors.green,
                      ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
          },
        ),
        title: const Text('Announcements'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateAnnouncementDialog,
            tooltip: 'Create Announcement',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _allAnnouncements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.announcement, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No announcements',
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create an announcement for a flight',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showCreateAnnouncementDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Announcement'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allAnnouncements.length,
                        itemBuilder: (context, index) {
                          final announcement = _allAnnouncements[index];
                          final flight = _flights.firstWhere(
                            (f) => f.id == announcement.flightId,
                            orElse: () => Flight(
                              id: announcement.flightId,
                              flightNumber: 'N/A',
                              departureAirportCode: '',
                              arrivalAirportCode: '',
                              airplaneId: 0,
                              departureTime: DateTime.now(),
                              arrivalTime: DateTime.now(),
                              status: '',
                              basePrice: 0,
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getAnnouncementIcon(announcement.type),
                                        color: _getAnnouncementColor(announcement.type),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          announcement.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getAnnouncementColor(announcement.type),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getAnnouncementColor(announcement.type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          announcement.type,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getAnnouncementColor(announcement.type),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Flight: ${flight.flightNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(announcement.message),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(announcement.createdAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _getAnnouncementColor(String type) {
    switch (type) {
      case 'Delay':
        return Colors.orange;
      case 'Cancellation':
        return Colors.red;
      case 'Gate Change':
        return Colors.blue;
      case 'Boarding Started':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'Delay':
        return Icons.schedule;
      case 'Cancellation':
        return Icons.cancel;
      case 'Gate Change':
        return Icons.door_front_door;
      case 'Boarding Started':
        return Icons.flight_takeoff;
      default:
        return Icons.info;
    }
  }
}

