import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }

  Future<void> _markRead(int id) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markNotificationAsRead(id);
      _loadNotifications();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _markAllRead() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markAllNotificationsAsRead();
      _loadNotifications();
    } catch (e) {
      // Ignore
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'BOOKING_EXPIRED':
        return Icons.timer_off;
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle;
      case 'FLIGHT_DELAY':
        return Icons.schedule;
      case 'FLIGHT_CANCELLED':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'BOOKING_EXPIRED':
      case 'FLIGHT_CANCELLED':
        return Colors.red;
      case 'BOOKING_CONFIRMED':
        return Colors.green;
      case 'FLIGHT_DELAY':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading notifications...')
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final bool isRead = n['is_read'];
                      final date = DateTime.parse(n['created_at']).toLocal();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(n['type']).withOpacity(0.1),
                          child: Icon(_getIcon(n['type']), color: _getColor(n['type'])),
                        ),
                        title: Text(
                          n['title'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['message']),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, HH:mm').format(date),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        tileColor: isRead ? null : Colors.blue.withOpacity(0.05),
                        onTap: () {
                          if (!isRead) _markRead(n['id']);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
