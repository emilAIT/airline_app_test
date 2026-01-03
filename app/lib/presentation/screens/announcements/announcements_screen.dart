import 'package:flutter/material.dart';
import 'package:airline_app/core/api_client.dart';

class AnnouncementsScreen extends StatefulWidget {
  final VoidCallback? onSearchFlights;
  
  const AnnouncementsScreen({super.key, this.onSearchFlights});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> with AutomaticKeepAliveClientMixin {
  late Future<List<dynamic>> _announcementsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() {
    setState(() {
      _announcementsFuture = _fetchAnnouncements();
    });
  }

  Future<List<dynamic>> _fetchAnnouncements() async {
    final apiClient = ApiClient();
    final response = await apiClient.get('/passenger/announcements');
    return response as List;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: () async {
        _loadAnnouncements();
        await _announcementsFuture;
      },
      child: FutureBuilder<List<dynamic>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Icon(Icons.error_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                const Text(
                  'Failed to load updates',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pull down to try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            );
          }

          final announcements = snapshot.data ?? [];

          if (announcements.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                const Text(
                  'All caught up!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No announcements at the moment.\nWe\'ll notify you of any flight updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: widget.onSearchFlights,
                  icon: const Icon(Icons.search),
                  label: const Text('Browse Flights'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
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
                      if (ann['flight_id'] != null)
                        Text(
                          'Flight ID: ${ann['flight_id']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAnnouncementType(ann['announcement_type']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF673AB7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: ann['created_at'] != null
                      ? Text(
                          _formatDate(ann['created_at']),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        )
                      : null,
                ),
              );
            },
          );
        },
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

  String _formatAnnouncementType(String? type) {
    if (type == null) return 'GENERAL';
    return type.toUpperCase().replaceAll('_', ' ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }
}
