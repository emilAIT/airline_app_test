import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/announcements_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/announcement.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late final ApiClient _apiClient;
  late final AnnouncementsApi _announcementsApi;
  List<Announcement> _announcements = [];
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
    _announcementsApi = AnnouncementsApi(_apiClient);
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcements = await _announcementsApi.getMyAnnouncements();
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadAnnouncements)
              : _announcements.isEmpty
                  ? const EmptyView(message: 'No announcements')
                  : RefreshIndicator(
                      onRefresh: _loadAnnouncements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.message,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        Formatters.formatDateTime(announcement.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
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

  IconData _getAnnouncementIcon(dynamic type) {
    final typeStr = type.toString().split('.').last;
    switch (typeStr) {
      case 'DELAY':
        return Icons.schedule;
      case 'CANCELLATION':
        return Icons.cancel;
      case 'GATE_CHANGE':
        return Icons.swap_horiz;
      case 'BOARDING_STARTED':
        return Icons.flight_takeoff;
      default:
        return Icons.info;
    }
  }

  Color _getAnnouncementColor(dynamic type) {
    final typeStr = type.toString().split('.').last;
    switch (typeStr) {
      case 'DELAY':
        return Colors.orange;
      case 'CANCELLATION':
        return Colors.red;
      case 'GATE_CHANGE':
        return Colors.blue;
      case 'BOARDING_STARTED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
