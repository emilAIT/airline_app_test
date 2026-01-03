import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'booking_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BookingProvider>().fetchUserBookings());
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final trips = bookingProvider.userBookings;

    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: bookingProvider.loading && trips.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? const Center(child: Text('No trips found'))
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (_, i) {
                    final t = trips[i];
                    final flight = t.flight;
                    final route = flight != null
                        ? '${flight.originCode} → ${flight.destinationCode}'
                        : 'Unknown Route';

                    return ListTile(
                      leading: const Icon(Icons.flight_takeoff),
                      title: Text(route),
                      subtitle: Text('PNR: ${t.pnr} | Status: ${t.status}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsScreen(booking: t),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}