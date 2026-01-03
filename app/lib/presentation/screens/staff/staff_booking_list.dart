import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/domain/entities/booking.dart';
import 'package:airline_app/data/repositories/staff_repository.dart';
import 'package:airline_app/presentation/cubits/staff_cubit.dart';

class StaffBookingList extends StatefulWidget {
  final List<Booking> bookings;
  const StaffBookingList({super.key, required this.bookings});

  @override
  State<StaffBookingList> createState() => _StaffBookingListState();
}

class _StaffBookingListState extends State<StaffBookingList> {
  final _searchController = TextEditingController();
  List<Booking> _filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _filteredBookings = widget.bookings;
  }

  @override
  void didUpdateWidget(StaffBookingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookings != widget.bookings) {
      _filteredBookings = widget.bookings;
      _applyFilter();
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBookings = widget.bookings;
      } else {
        _filteredBookings = widget.bookings.where((booking) {
          return booking.pnr.toLowerCase().contains(query) ||
                 booking.id.toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel booking ${booking.pnr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<StaffRepository>().cancelBooking(booking.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
          context.read<StaffCubit>().loadDashboardData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking ${booking.pnr}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Passenger', booking.passengerName ?? 'N/A'),
              _DetailRow('PNR', booking.pnr),
              _DetailRow('Booking ID', '#${booking.id}'),
              _DetailRow('Flight ID', '#${booking.flightId}'),
              _DetailRow('Status', booking.status.name.toUpperCase()),
              const Divider(height: 24),
              const Text('Tickets:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...booking.tickets.map((ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${ticket.seatNumber} (${ticket.ticketNumber})'),
              )),
            ],
          ),
        ),
        actions: [
          if (booking.status != BookingStatus.cancelled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking);
              },
              child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by PNR or Booking ID',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilter();
                      },
                    )
                  : null,
            ),
            onChanged: (value) => _applyFilter(),
          ),
        ),
        Expanded(
          child: _filteredBookings.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No bookings found'
                        : 'No bookings match your search',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF673AB7),
                          child: Icon(Icons.book_online, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          booking.passengerName ?? 'Unknown Passenger',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'PNR: ${booking.pnr} | Flight #${booking.flightId}\nSeats: ${booking.tickets.map((t) => t.seatNumber).join(", ")}',
                        ),
                        trailing: _StatusBadge(status: booking.status),
                        onTap: () => _showBookingDetails(booking),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    if (status == BookingStatus.confirmed) color = Colors.green;
    if (status == BookingStatus.cancelled) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
