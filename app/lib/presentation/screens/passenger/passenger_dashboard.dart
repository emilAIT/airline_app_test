import 'package:flutter/material.dart';
import 'package:airline_app/presentation/screens/flights/flight_search_screen.dart';
import 'package:airline_app/presentation/screens/bookings/trips_screen.dart';
import 'package:airline_app/presentation/screens/announcements/announcements_screen.dart';

class PassengerDashboard extends StatefulWidget {
  const PassengerDashboard({super.key});

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const FlightSearchScreen(),
      TripsScreen(
        onSearchFlights: () => setState(() => _currentIndex = 0),
      ),
      AnnouncementsScreen(
        onSearchFlights: () => setState(() => _currentIndex = 0),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Updates',
          ),
        ],
      ),
    );
  }
}
