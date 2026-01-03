import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/flight.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../services/flight_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../services/booking_service.dart';
import 'package:dio/dio.dart';
import 'passenger_main_screen.dart';

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.read(dioProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider));
});

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type;
  final bool isRead;
  final int? flightId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.flightId,
  });
}

class PassengerAnnouncementsScreen extends ConsumerStatefulWidget {
  const PassengerAnnouncementsScreen({super.key});

  @override
  ConsumerState<PassengerAnnouncementsScreen> createState() => _PassengerAnnouncementsScreenState();
}

class _PassengerAnnouncementsScreenState extends ConsumerState<PassengerAnnouncementsScreen> {
  // List of IDs that user has "seen" and cleared
  Set<String> _clearedNotificationIds = {};
  DateTime? _lastClearedTime;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _lastRefreshCount = 0;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload notifications when screen becomes visible again
    final now = DateTime.now();
    if (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 2) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
        // User requested refresh. According to requirements:
        // "if user read notifications then when he refreshes it all notifications will be erased"
        // We treat the current moment as the "clear point". Any notification created BEFORE now is considered cleared/hidden.
        setState(() {
            _lastClearedTime = DateTime.now();
            _notifications = []; // Clear current view immediately
        });
    }

    setState(() {
      _isLoading = !isRefresh; // Don't show full loader on refresh
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        throw Exception('Not authenticated');
      }

      final bookingService = ref.read(bookingServiceProvider);
      final flightService = ref.read(flightServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      List<NotificationItem> items = [];

      // 1. Load User Notifications from database (booking/payment notifications)
      try {
        final userNotifications = await notificationService.getNotifications(
          token: authState.token!,
        );
        
        for (var notification in userNotifications) {
          final id = 'notification_${notification.id}';
          
          // Filter logic: skip if cleared
          if (_lastClearedTime != null && notification.createdAt.isBefore(_lastClearedTime!)) {
            continue;
          }

          // Determine title and type based on notification type
          String title;
          String type;
          if (notification.type == 'Booking Confirmed') {
            title = 'Booking Created';
            type = 'booking';
          } else if (notification.type == 'Ticket Purchased') {
            title = 'Ticket Purchased';
            type = 'booking';
          } else if (notification.type == 'Flight Update') {
            title = 'Flight Update';
            type = 'system';
          } else {
            title = notification.type;
            type = 'system';
          }

          items.add(NotificationItem(
            id: id,
            title: title,
            message: notification.message,
            createdAt: notification.createdAt,
            type: type,
            isRead: notification.isRead,
          ));
        }
      } catch (e) {
        // Ignore notification service errors, continue with announcements
        print('Error loading user notifications: $e');
      }

      // 2. Fetch Flight Announcements
      final bookings = await bookingService.getMyBookings(token: authState.token!);
      for (var booking in bookings) {
        if (booking.flight != null) {
          try {
            final announcements = await flightService.getFlightAnnouncements(
              booking.flight!.id,
              token: authState.token,
            );
            
            for (var a in announcements) {
              final id = 'announcement_${a.id}';
              
              // Filter logic: skip if cleared
              if (_lastClearedTime != null && a.createdAt.isBefore(_lastClearedTime!)) {
                  continue;
              }

              // Deduplicate: Check if we already have this ID
              if (items.any((item) => item.id == id)) {
                continue; 
              }

              items.add(NotificationItem(
                id: id,
                title: a.title,
                message: a.message,
                createdAt: a.createdAt,
                type: 'announcement', 
                flightId: booking.flight!.id,
                isRead: false,
              ));
            }
          } catch (e) {
            // Ignore individual flight announcement fetch errors
          }
        }
      }

      // 3. Sort by Date (Desc) - newest first
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
        
        if (isRefresh && items.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications cleared')),
             );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,


        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
               ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
           onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All marked as read')),
              );
            },
            tooltip: 'Mark all as read',
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
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bellOff, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadNotifications(isRefresh: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    IconData icon;
    Color iconColor;
    Color badgeColor;
    String badgeText;

    switch (item.type) {
      case 'booking':
        // Check title to determine if it's booking created or ticket purchased
        if (item.title == 'Ticket Purchased') {
          icon = LucideIcons.checkCircle;
          iconColor = Colors.green;
          badgeColor = Colors.green;
          badgeText = 'Purchased';
        } else {
          icon = LucideIcons.ticket;
          iconColor = Colors.blue;
          badgeColor = Colors.blue;
          badgeText = 'Booking';
        }
        break;
      case 'system':
        icon = LucideIcons.checkCircle;
        iconColor = Colors.green;
        badgeColor = Colors.green;
        badgeText = 'System';
        break;
      case 'announcement':
        icon = LucideIcons.megaphone;
        iconColor = Colors.orange;
        badgeColor = Colors.orange;
        badgeText = 'Announcement';
        break;
      case 'admin': // Mock type
        icon = LucideIcons.shieldAlert;
        iconColor = Colors.red;
        badgeColor = Colors.red;
        badgeText = 'Official';
        break;
      default:
        icon = LucideIcons.info;
        iconColor = AppTheme.textSecondary;
        badgeColor = Colors.grey;
        badgeText = 'Info';
    }

    // Heuristic for "Official" based on title for now if type is generic
    if (item.title.contains('Urgent') || item.title.contains('Important')) {
      badgeText = 'Official';
      badgeColor = Colors.red;
      icon = LucideIcons.alertTriangle;
      iconColor = Colors.red;
    }

    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          badgeText.toUpperCase(),
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, HH:mm').format(item.createdAt),
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
