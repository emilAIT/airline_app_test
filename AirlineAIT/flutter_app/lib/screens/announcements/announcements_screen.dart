import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getMyAnnouncements();

      if (mounted) {
        setState(() {
          _announcements = List<dynamic>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load announcements';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadAnnouncements,
      );
    }

    if (_announcements.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Announcements',
        message: 'You don\'t have any flight announcements',
        icon: Icons.notifications_none,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          return _buildAnnouncementCard(_announcements[index]);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final createdAt = DateTime.parse(announcement['created_at']);
    final type = announcement['type'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(type),
                  backgroundColor: _getTypeColor(type).withValues(alpha: 0.2),
                ),
                const Spacer(),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement['title'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              announcement['message'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'DELAY':
        return Icons.schedule;
      case 'CANCELLATION':
        return Icons.cancel;
      case 'GATE_CHANGE':
        return Icons.directions_walk;
      case 'BOARDING_STARTED':
        return Icons.flight_takeoff;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
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

