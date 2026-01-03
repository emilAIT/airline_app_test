import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/auth_service.dart';
import '../../app/router.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.flight,
            title: 'Manage Airplanes',
            color: Colors.blue,
            onTap: () => Navigator.of(context).pushNamed(AppRouter.staffAirplanes),
          ),
          _buildMenuCard(
            context,
            icon: Icons.flight_takeoff,
            title: 'Manage Flights',
            color: Colors.green,
            onTap: () => Navigator.of(context).pushNamed(AppRouter.staffFlights),
          ),
          _buildMenuCard(
            context,
            icon: Icons.book_online,
            title: 'Manage Bookings',
            color: Colors.orange,
            onTap: () => Navigator.of(context).pushNamed(AppRouter.staffBookings),
          ),
          _buildMenuCard(
            context,
            icon: Icons.campaign,
            title: 'Announcements',
            color: Colors.purple,
            onTap: () => Navigator.of(context).pushNamed(AppRouter.staffAnnouncements),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

