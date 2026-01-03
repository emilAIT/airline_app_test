import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/bookings_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';
import '../../app/router.dart';

class TripDetailsPage extends StatefulWidget {
  final int bookingId;

  const TripDetailsPage({super.key, required this.bookingId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  late final ApiClient _apiClient;
  late final BookingsApi _bookingsApi;
  Booking? _booking;
  bool _isLoading = false;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _bookingsApi = BookingsApi(_apiClient);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get booking - need booking ID or PNR
      // For now, get from my bookings
      final bookings = await _bookingsApi.getMyBookings();
      final booking = bookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => bookings.first,
      );
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await _bookingsApi.cancelBooking(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isCancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadDetails)
              : _booking == null
                  ? const Center(child: Text('No data'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final booking = _booking!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PNR: ${booking.pnr}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text(booking.status.name),
                        backgroundColor: _getStatusColor(booking.status),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Booking Date', Formatters.formatDate(booking.createdAt)),
                  _buildInfoRow('Total Price', '\$${booking.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Passengers & Tickets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...(booking.tickets ?? []).map((ticket) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(ticket.passengerName.substring(0, 1).toUpperCase()),
                ),
                title: Text(ticket.passengerName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat: ${ticket.seatNumber}'),
                    Text('Ticket: ${ticket.ticketNumber}'),
                  ],
                ),
                trailing: booking.status == BookingStatus.CONFIRMED
                    ? IconButton(
                        icon: const Icon(Icons.login),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.checkin,
                            arguments: ticket.id,
                          );
                        },
                      )
                    : null,
              ),
            );
          }),
          if (booking.status.name == 'CONFIRMED')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  icon: const Icon(Icons.cancel),
                  label: _isCancelling
                      ? const Text('Cancelling...')
                      : const Text('Cancel Booking'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last;
    switch (statusStr) {
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
