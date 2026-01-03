import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/ticket.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';

class BookingDetailsStaffPage extends StatefulWidget {
  final String pnr;

  const BookingDetailsStaffPage({super.key, required this.pnr});

  @override
  State<BookingDetailsStaffPage> createState() => _BookingDetailsStaffPageState();
}

class _BookingDetailsStaffPageState extends State<BookingDetailsStaffPage> {
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  
  Booking? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _staffApi = StaffApi(_apiClient);
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);

    try {
      final booking = await _staffApi.searchBooking(widget.pnr);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel booking ${_booking!.pnr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _staffApi.cancelBooking(_booking!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        _loadBooking(); // Reload to show updated status
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  Future<void> _reassignSeat(Ticket ticket) async {
    final controller = TextEditingController(text: ticket.seatNumber);
    
    final newSeat = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Seat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger: ${ticket.passengerName}'),
            Text('Current Seat: ${ticket.seatNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Seat Number',
                hintText: 'e.g., 12A',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );

    if (newSeat == null || newSeat.isEmpty || newSeat == ticket.seatNumber) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _staffApi.reassignSeat(ticketId: ticket.id, newSeatNumber: newSeat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seat reassigned to $newSeat')),
        );
        _loadBooking(); // Reload to show updated seat
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reassign: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const LoadingView(),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final canCancel = _booking!.status.name != 'CANCELLED' && 
                      _booking!.flight != null &&
                      _booking!.flight!.departureTime.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking ${_booking!.pnr}'),
        actions: [
          if (canCancel && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelBooking,
              tooltip: 'Cancel Booking',
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _buildInfoRow('PNR', _booking!.pnr),
                        _buildInfoRow('Status', _booking!.status.name),
                        _buildInfoRow('Total Price', '\$${_booking!.totalPrice.toStringAsFixed(2)}'),
                        _buildInfoRow('Booked On', Formatters.formatDateTime(_booking!.createdAt)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Flight Info Card
                if (_booking!.flight != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flight Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          _buildInfoRow('Flight', _booking!.flight!.flightNumber),
                          _buildInfoRow('From', _booking!.flight!.origin?.city ?? 'N/A'),
                          _buildInfoRow('To', _booking!.flight!.destination?.city ?? 'N/A'),
                          _buildInfoRow('Departure', Formatters.formatDateTime(_booking!.flight!.departureTime)),
                          _buildInfoRow('Gate', _booking!.flight!.gate ?? 'Not assigned'),
                          _buildInfoRow('Terminal', _booking!.flight!.terminal ?? 'Not assigned'),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Passengers & Tickets
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passengers (${_booking!.tickets?.length ?? 0})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        if (_booking!.tickets != null)
                          ..._booking!.tickets!.map((ticket) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(ticket.passengerName[0]),
                                ),
                                title: Text(ticket.passengerName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Passport: ${ticket.passportNumber}'),
                                    Text('Seat: ${ticket.seatNumber} (${ticket.seatCategory.name})'),
                                    Text('Price: \$${ticket.price.toStringAsFixed(2)}'),
                                  ],
                                ),
                                trailing: _booking!.status.name == 'CONFIRMED' && !_isProcessing
                                    ? IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _reassignSeat(ticket),
                                        tooltip: 'Reassign Seat',
                                      )
                                    : null,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
