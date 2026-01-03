import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'home_screen_new.dart';
import 'explore_screen.dart'; // Added Explore
import 'my_trips_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';
import 'staff_dashboard_screen.dart';
import 'payment_screen.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/pending_booking_banner.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  List<dynamic> _pendingBookings = [];
  bool _isLoadingPending = true;

  final List<Widget> _passengerScreens = [
    const HomeScreenNew(),
    const MyTripsScreen(),
    const ExploreScreen(), // New Explore Widget
    const AnnouncementsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingBookings();
  }

  Future<void> _loadPendingBookings() async {
    try {
      final pending = await _apiService.getPendingBookings();
      if (mounted) {
        setState(() {
          _pendingBookings = pending;
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPending = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload pending bookings when screen changes
    if (_currentIndex == 1) {
      _loadPendingBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Staff users get the staff dashboard without bottom nav
    if (authProvider.isStaff) {
      return const StaffDashboardScreen();
    }

    return Scaffold(
      extendBody: true, // For transparent/floating nav bar
      body: Stack(
        children: [
          _passengerScreens[_currentIndex],
          // Persistent banner for PENDING bookings
          if (!_isLoadingPending && _pendingBookings.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PendingBookingBanner(
                pendingBookings: _pendingBookings,
                onPaymentPressed: () {
                  if (_pendingBookings.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          bookingId: _pendingBookings[0]['id'],
                        ),
                      ),
                    ).then((_) => _loadPendingBookings());
                  }
                },
                onDismiss: () {
                  setState(() {
                    _pendingBookings = [];
                  });
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: EldiyarTheme.cardBackground.withOpacity(0.90), // Slightly more opaque
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: EldiyarTheme.primaryBlue.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: EldiyarTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 80, // Increased height for better touch targets
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildNavItem(icon: Icons.flight_takeoff, label: 'Flights', index: 0),
                   _buildNavItem(icon: Icons.confirmation_number, label: 'Trips', index: 1),
                   _buildNavItem(icon: Icons.explore, label: 'Explore', index: 2),
                   _buildNavItem(icon: Icons.notifications_active, label: 'Alerts', index: 3),
                   _buildNavItem(icon: Icons.person, label: 'Profile', index: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          // Reload pending bookings when navigating to Trips
          if (index == 1) {
            _loadPendingBookings();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8), // Reduced horizontal margin
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? EldiyarTheme.primaryBlue.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: EldiyarTheme.primaryBlue.withOpacity(0.6),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? EldiyarTheme.primaryBlue
                    : EldiyarTheme.textSecondary.withOpacity(0.7),
                size: isSelected ? 28 : 24, // Increased icon sizes
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // Increased font size
                  fontFamily: 'RobotoMono',
                  color: isSelected
                      ? EldiyarTheme.primaryBlue
                      : EldiyarTheme.textSecondary.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
