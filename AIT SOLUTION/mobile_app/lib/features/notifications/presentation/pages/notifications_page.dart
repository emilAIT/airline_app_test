import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ait_airlines/core/widgets/common_app_bar.dart';
import '../bloc/notification_bloc.dart';
import '../../domain/entities/notification.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh on open
    context.read<NotificationBloc>().add(const LoadNotifications());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CommonAppBar(
        title: 'Notifications',
        showHomeButton: true,
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is NotificationError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(const LoadNotifications(refresh: true));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationCard(notification: notification);
                },
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoaded && state.unreadCount > 0) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.read<NotificationBloc>().add(MarkAllAsRead());
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
              backgroundColor: const Color(0xFF1A1A2E),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.white : const Color(0xFFE8EAF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(MarkAsRead(notification.id));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE94560),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, HH:mm').format(notification.createdAt.toLocal()),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.bookingCreated:
        iconData = Icons.bookmark_added;
        color = Colors.blue;
        break;
      case NotificationType.bookingPaid:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.bookingExpired:
        iconData = Icons.timer_off;
        color = Colors.orange;
        break;
      case NotificationType.bookingCancelled:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.flightUpdate:
      case NotificationType.flightDelayed:
        iconData = Icons.flight_takeoff;
        color = Colors.amber;
        break;
      case NotificationType.staffAnnouncement:
        iconData = Icons.campaign;
        color = const Color(0xFFE94560);
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }
}
