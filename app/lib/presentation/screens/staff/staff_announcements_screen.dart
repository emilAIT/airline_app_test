import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/core/api_client.dart';
import 'package:airline_app/data/repositories/staff_repository.dart';

class StaffAnnouncementsScreen extends StatefulWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  State<StaffAnnouncementsScreen> createState() => _StaffAnnouncementsScreenState();
}

class _StaffAnnouncementsScreenState extends State<StaffAnnouncementsScreen> {
  late Future<List<dynamic>> _announcementsFuture;
  late Future<List<dynamic>> _flightsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      final apiClient = ApiClient();
      _announcementsFuture = apiClient.get('/staff/announcements').then((data) => data as List);
      _flightsFuture = context.read<StaffRepository>().getAllFlights().then((flights) => 
        flights.map((f) => {'id': f.id, 'flight_number': f.flightNumber}).toList()
      );
    });
  }

  Future<void> _deleteAnnouncement(int announcementId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.delete('/staff/announcements/$announcementId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCreateDialog() async {
    final flights = await _flightsFuture;
    
    if (!mounted) return;
    
    int? selectedFlightId;
    String? selectedType;
    final messageController = TextEditingController();
    
    final types = ['DELAY', 'CANCELLATION', 'GATE_CHANGE', 'BOARDING', 'GENERAL'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Flight'),
                  items: flights.map((f) {
                    return DropdownMenuItem<int>(
                      value: f['id'],
                      child: Text('Flight ${f['flight_number']}'),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedFlightId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: types.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedType = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                if (selectedFlightId == null || selectedType == null || messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                
                try {
                  final apiClient = ApiClient();
                  await apiClient.post('/staff/announcements', body: {
                    'flight_id': selectedFlightId,
                    'announcement_type': selectedType,
                    'message': messageController.text,
                  });
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement created successfully')),
                  );
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
      body: FutureBuilder<List<dynamic>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final announcements = snapshot.data ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No announcements yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Announcement'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final ann = announcements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _getAnnouncementIcon(ann['announcement_type']),
                  title: Text(
                    ann['message'] ?? 'No message',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Flight ID: ${ann['flight_id']}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        ann['announcement_type']?.toString().toUpperCase().replaceAll('_', ' ') ?? 'GENERAL',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF673AB7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Announcement'),
                          content: const Text('Are you sure you want to delete this announcement?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteAnnouncement(ann['id']);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getAnnouncementIcon(String? type) {
    IconData icon;
    Color color;
    
    switch (type?.toUpperCase()) {
      case 'DELAY':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'CANCELLATION':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'GATE_CHANGE':
        icon = Icons.meeting_room;
        color = Colors.blue;
        break;
      case 'BOARDING':
        icon = Icons.flight_takeoff;
        color = Colors.green;
        break;
      default:
        icon = Icons.campaign;
        color = const Color(0xFF673AB7);
    }
    
    return Icon(icon, color: color);
  }
}
