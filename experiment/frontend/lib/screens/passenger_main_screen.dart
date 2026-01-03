import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Using Lucide icons for modern look
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'flight_search_screen.dart';
import 'my_trips_screen.dart';
import 'passenger_announcements_screen.dart';
import 'profile_screen.dart';
import 'airports_screen.dart';

// Define provider for the GlobalKey
final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) => GlobalKey<ScaffoldState>());

// ValueNotifier for managing current tab index
final currentTabIndexNotifier = ValueNotifier<int>(0);

// Provider for managing current tab index
final currentTabIndexProvider = Provider<ValueNotifier<int>>((ref) => currentTabIndexNotifier);

class PassengerMainScreen extends ConsumerStatefulWidget {
  const PassengerMainScreen({super.key});

  @override
  ConsumerState<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends ConsumerState<PassengerMainScreen> {
  final List<Widget> _screens = [
    const FlightSearchScreen(),
    const MyTripsScreen(),
    const PassengerAnnouncementsScreen(),
    const AirportsScreen(),
    const ProfileScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    // Watch the key so it persists (provider builds once)
    final scaffoldKey = ref.watch(mainScaffoldKeyProvider);
    final tabNotifier = ref.watch(currentTabIndexProvider);

    return ValueListenableBuilder<int>(
      valueListenable: tabNotifier,
      builder: (context, currentIndex, child) {
        return Scaffold(
      key: scaffoldKey, // Assign the key
      drawer: Drawer(
        backgroundColor: AppTheme.surfaceColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Astra Air',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer(
                      builder: (context, ref, child) {
                        final user = ref.watch(authProvider).user;
                        return Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        );
                      }
                    ),
                    // Removed Big Circle Icon for minimalism
                  ],
                ),
              ),
            ),
            _buildDrawerItem(0, 'Search Flights', LucideIcons.search),
            _buildDrawerItem(1, 'My Trips', LucideIcons.plane),
            _buildDrawerItem(2, 'Notifications', LucideIcons.bell),
            _buildDrawerItem(3, 'Airports', LucideIcons.mapPin),
            _buildDrawerItem(4, 'Profile', LucideIcons.user),
            const Spacer(),
            const Divider(color: Color(0xFF334155)),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: AppTheme.errorColor),
              title: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                // AuthWrapper will handle navigation
                if (context.mounted) Navigator.pop(context); // Close drawer
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
    );
      },
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Search Flights';
      case 1: return 'My Trips';
      case 2: return 'Notifications';
      case 3: return 'Airports';
      case 4: return 'Profile';
      default: return 'Astra Air';
    }
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final tabNotifier = ref.watch(currentTabIndexProvider);
    return ValueListenableBuilder<int>(
      valueListenable: tabNotifier,
      builder: (context, currentIndex, child) {
        final isSelected = currentIndex == index;
        return ListTile(
          leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onTap: () {
            tabNotifier.value = index;
            Navigator.pop(context); // Close drawer
          },
        );
      },
    );
  }
}
