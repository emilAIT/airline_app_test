import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../flights/flight_search_screen.dart';
import '../bookings/my_trips_screen.dart';
import '../bookings/pending_bookings_screen.dart';
import '../profile/profile_screen.dart';
import '../announcements/announcements_screen.dart';
import '../notifications/notification_screen.dart';
import '../payments/payment_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  int _unreadCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkNotifications();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNotifications() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getNotifications();
      final List notifications = response.data;
      final unread = notifications.where((n) => !n['is_read']).length;
      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  final List<Widget> _screens = [
    const FlightSearchScreen(),
    const PendingBookingsScreen(),
    const MyTripsScreen(),
    const AnnouncementsScreen(),
    const PaymentHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/photos/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.flight),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'IBO airlines',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  ).then((_) => _checkNotifications());
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (user != null && MediaQuery.of(context).size.width > 600)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
                child: Center(
                  child: Text(
                    user['email'] ?? '',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              accountName: const Text('Passenger'),
              accountEmail: Text(user?['email'] ?? 'Guest'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Search'),
                    selected: _currentIndex == 0,
                    onTap: () {
                      print('DEBUG: Tapped Search');
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined),
                    title: const Text('Bookings'),
                    selected: _currentIndex == 1,
                    onTap: () {
                      print('DEBUG: Tapped Bookings');
                      setState(() => _currentIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.flight),
                    title: const Text('My Trips'),
                    selected: _currentIndex == 2,
                    onTap: () {
                      print('DEBUG: Tapped My Trips');
                      setState(() => _currentIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Announcements'),
                    selected: _currentIndex == 3,
                    onTap: () {
                      print('DEBUG: Tapped Announcements');
                      setState(() => _currentIndex = 3);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Payments'),
                    selected: _currentIndex == 4,
                    onTap: () {
                      print('DEBUG: Tapped Payments');
                      setState(() => _currentIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    selected: _currentIndex == 5,
                    onTap: () {
                      print('DEBUG: Tapped Profile');
                      setState(() => _currentIndex = 5);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      print('DEBUG: Tapped Logout');
                      Navigator.pop(context);
                      authService.logout();
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
    );
  }
}

