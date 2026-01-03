import 'package:flutter/material.dart';
import 'manage_flights_screen.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Dashboard')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.flight),
            title: const Text('Manage Flights'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageFlightsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Announcements'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}