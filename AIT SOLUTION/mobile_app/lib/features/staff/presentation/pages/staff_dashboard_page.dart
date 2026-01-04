import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_event.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final userName = state is AuthAuthenticated ? (state.user.firstName ?? 'Staff') : 'Staff';

          return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            appBar: AppBar(
              title: const Text('STAFF PANEL', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () => _showLogoutDialog(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Operational Management Dashboard',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'MY FLEET & FLIGHTS',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLargeActionCard(
                    context,
                    'Manage My Airplanes',
                    'Register, view and delete your aircrafts',
                    Icons.airplanemode_active,
                    const Color(0xFFE94560),
                    '/airplanes',
                  ),
                  const SizedBox(height: 16),
                  _buildLargeActionCard(
                    context,
                    'Manage Flights',
                    'Schedule new flights and update statuses',
                    Icons.flight_takeoff,
                    Colors.blueAccent,
                    '/flights',
                  ),
                  
                  const SizedBox(height: 40),
                  const Text(
                    'INFRASTRUCTURE',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLargeActionCard(
                    context,
                    'Global Airports',
                    'Register and view all available airports',
                    Icons.location_on_outlined,
                    Colors.tealAccent,
                    '/airports', // Need to make sure this exists
                  ),
                  
                  const SizedBox(height: 40),
                  const Text(
                    'COMMUNICATION',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLargeActionCard(
                    context,
                    'Create Announcement',
                    'Send announcements to all flights or specific flight',
                    Icons.announcement,
                    Colors.purpleAccent,
                    '/announcements/create',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Confirm logout from Staff Panel?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
