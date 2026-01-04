import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_event.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.redAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text('Administrator',
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Staff Approvals'),
              onTap: () {
                context.push('/admin/staff');
              },
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text('Users & Staff'),
              onTap: () {
                context.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.airplanemode_active),
              title: const Text('Manage All Airplanes'),
              onTap: () {
                context.go('/airplanes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Logout'),
              onTap: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(context, 'Total Users', '1,234', Icons.people,
                      Colors.blue),
                  _buildStatCard(context, 'Active Flights', '42',
                      Icons.flight_takeoff, Colors.green),
                  _buildStatCard(context, 'Total Bookings', '8,500',
                      Icons.book_online, Colors.orange),
                  _buildStatCard(context, 'System Status', 'Healthy',
                      Icons.check_circle, Colors.teal),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Staff Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildWideActionCard(
                context,
                'Manage Staff Approvals',
                'Approve or reject new staff account requests',
                Icons.people_alt_rounded,
                Colors.orange,
                () => context.push('/admin/staff'),
              ),
              const SizedBox(height: 16),
              _buildWideActionCard(
                context,
                'Manage All Airplanes',
                'Global list of fleet and ownership',
                Icons.airplanemode_active,
                Colors.blue,
                () => context.push('/airplanes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildWideActionCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
