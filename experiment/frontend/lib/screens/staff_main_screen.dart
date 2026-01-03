import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'staff_flights_screen.dart';
import 'staff_airplanes_screen.dart';
import 'staff_bookings_screen.dart';
import 'staff_announcements_screen.dart';
import 'staff_dashboard_screen.dart';
import 'login_screen.dart';

final staffScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) => GlobalKey<ScaffoldState>());

class StaffMainScreen extends ConsumerStatefulWidget {
  const StaffMainScreen({super.key});

  @override
  ConsumerState<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends ConsumerState<StaffMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StaffDashboardScreen(),
    const StaffFlightsScreen(),
    const StaffBookingsScreen(),
    const StaffAnnouncementsScreen(),
    const StaffAirplanesScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Flights',
    'Bookings',
    'Announcements',
    'Airplanes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ref.read(staffScaffoldKeyProvider),
      backgroundColor: AppTheme.backgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Text(
                'Staff Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flight),
              title: const Text('Flights'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Bookings'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Announcements'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.airplanemode_active),
              title: const Text('Airplanes'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    // Navigate to login screen after logout
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
