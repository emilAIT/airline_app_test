import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/staff_service.dart';
import '../services/flight_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'staff_main_screen.dart';

StaffService _getStaffService(WidgetRef ref) {
  final authState = ref.read(authProvider);
  return StaffService(ref.read(dioProvider), token: authState.token);
}

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  int _flightsToday = 0;
  int _delayedFlights = 0;
  int _boardingFlights = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      if (authState.token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final staffService = _getStaffService(ref);
      final flights = await staffService.getFlights();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      int flightsToday = 0;
      int delayedFlights = 0;
      int boardingFlights = 0;

      for (var flight in flights) {
        if (flight.departureTime.isAfter(todayStart) && flight.departureTime.isBefore(todayEnd)) {
          flightsToday++;
        }
        if (flight.status.toString() == 'DELAYED') {
          delayedFlights++;
        }
        if (flight.status.toString() == 'BOARDING') {
          boardingFlights++;
        }
      }

      setState(() {
        _flightsToday = flightsToday;
        _delayedFlights = delayedFlights;
        _boardingFlights = boardingFlights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
              ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Today\'s Overview',
            style: TextStyle(
              fontSize: 24, // Increased size
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatBlock('Flights Today', _flightsToday.toString(), LucideIcons.plane, AppTheme.primaryColor),
          const SizedBox(height: 16),
          _buildStatBlock('Delayed Flights', _delayedFlights.toString(), LucideIcons.alertTriangle, AppTheme.warningColor),
          const SizedBox(height: 16),
          _buildStatBlock('Boarding Flights', _boardingFlights.toString(), LucideIcons.users, AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, IconData icon, Color color) {
    return Card( // Changed Container to Card
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24), // Increased padding
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle( // Removed hardcoded color, uses textPrimary from theme or inherited
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

