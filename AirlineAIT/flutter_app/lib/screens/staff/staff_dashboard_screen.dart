import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_flights_screen.dart';
import '../admin/admin_airports_screen.dart';
import '../admin/admin_airplanes_screen.dart';
import '../admin/admin_bookings_screen.dart';
import '../admin/admin_announcements_screen.dart';
import '../admin/admin_payments_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _sections = [
    {'title': 'Flights', 'icon': Icons.flight, 'widget': const AdminFlightsScreen()},
    {'title': 'Airports', 'icon': Icons.location_city, 'widget': const AdminAirportsScreen()},
    {'title': 'Airplanes', 'icon': Icons.airplanemode_active, 'widget': const AdminAirplanesScreen()},
    {'title': 'Bookings', 'icon': Icons.book, 'widget': const AdminBookingsScreen()},
    {'title': 'Announcements', 'icon': Icons.notifications, 'widget': const AdminAnnouncementsScreen()},
    {'title': 'Payments', 'icon': Icons.payments, 'widget': const AdminPaymentsScreen()},
    {'title': 'My Profile', 'icon': Icons.person, 'widget': const ProfileScreen(showAppBar: false)},
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_sections[_currentIndex]['title']),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  user['email'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Staff Member'),
              accountEmail: Text(user?['email'] ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(_sections[index]['icon']),
                    title: Text(_sections[index]['title']),
                    selected: _currentIndex == index,
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                      Navigator.pop(context); // Close drawer
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _sections[_currentIndex]['widget'],
    );
  }
}



