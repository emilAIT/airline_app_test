// Admin dashboard screen with navigation drawer.
//
// Provides access to all admin sections:
// Staff, Pending Staff, Flights, Airports, Airplanes,
// Bookings, Announcements, Payments.
//
// Part of: Flutter Frontend / Admin Screens
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'admin_staff_screen.dart';
import 'admin_pending_staff_screen.dart';
import 'admin_flights_screen.dart';
import 'admin_airports_screen.dart';
import 'admin_airplanes_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_payments_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _sections = [
    {'title': 'Staff Overview', 'icon': Icons.people, 'widget': const AdminStaffScreen()},
    {'title': 'Pending Staff', 'icon': Icons.person_add, 'widget': const AdminPendingStaffScreen()},
    {'title': 'Flights', 'icon': Icons.flight, 'widget': const AdminFlightsScreen()},
    {'title': 'Airports', 'icon': Icons.location_city, 'widget': const AdminAirportsScreen()},
    {'title': 'Airplanes', 'icon': Icons.airplanemode_active, 'widget': const AdminAirplanesScreen()},
    {'title': 'Manage Bookings', 'icon': Icons.book, 'widget': const AdminBookingsScreen()},
    {'title': 'Announcements', 'icon': Icons.notifications, 'widget': const AdminAnnouncementsScreen()},
    {'title': 'Payments', 'icon': Icons.payments, 'widget': const AdminPaymentsScreen()},
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
              accountName: const Text('Administrator'),
              accountEmail: Text(user?['email'] ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.admin_panel_settings, size: 40),
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
