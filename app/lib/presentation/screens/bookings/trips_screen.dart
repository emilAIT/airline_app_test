import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/data/repositories/booking_repository.dart';
import 'package:airline_app/domain/entities/booking.dart';
import 'package:airline_app/presentation/screens/bookings/checkin_screen.dart';

class TripsScreen extends StatefulWidget {
  final VoidCallback? onSearchFlights;
  
  const TripsScreen({super.key, this.onSearchFlights});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with AutomaticKeepAliveClientMixin {
  late Future<List<Booking>> _tripsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload trips whenever this screen becomes visible
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _tripsFuture = context.read<BookingRepository>().getMyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: () async {
        _loadTrips();
        await _tripsFuture;
      },
      child: FutureBuilder<List<Booking>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.flight_takeoff_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No trips yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start exploring destinations and book your first flight!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to search tab (index 0)
                    widget.onSearchFlights?.call();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search Flights'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final booking = trips[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TripCard(
                  booking: booking,
                  onTap: () {
                    if (booking.status == BookingStatus.confirmed) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckinScreen(booking: booking),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _TripCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PNR: ${booking.pnr}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.name.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.flight_takeoff, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text('Seat: ', style: TextStyle(color: Colors.grey)),
                  Text(
                    booking.tickets.isNotEmpty ? booking.tickets.first.seatNumber : 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (booking.status == BookingStatus.confirmed)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Tap for Boarding Pass ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.cancelled: return Colors.red;
      default: return Colors.orange;
    }
  }
}
