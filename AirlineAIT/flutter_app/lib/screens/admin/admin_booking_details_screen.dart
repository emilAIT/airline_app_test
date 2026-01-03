import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class AdminBookingDetailsScreen extends StatefulWidget {
  final int bookingId;

  const AdminBookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<AdminBookingDetailsScreen> createState() => _AdminBookingDetailsScreenState();
}

class _AdminBookingDetailsScreenState extends State<AdminBookingDetailsScreen> {
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // We use getStaffBookings with ID logic? No, let's use the new endpoint we just updated
      // Actually, ApiService.getBookingDetails calls /bookings/$bookingId which is passenger route.
      // We need a way to call the staff one if we want to ensure staff permissions are used, 
      // but if the passenger one works and staff have access, it's fine.
      // However, the staff one we just updated is at /staff/bookings/$bookingId.
      // Let's add that to ApiService.
      
      final response = await _getBookingData(apiService);
      
      if (mounted) {
        setState(() {
          _bookingData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load booking details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<dynamic> _getBookingData(ApiService apiService) async {
    return await apiService.getStaffBookingDetails(widget.bookingId);
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.cancelStaffBooking(widget.bookingId);
      await _loadBookingDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details: ${_bookingData?['pnr'] ?? ''}'),
        actions: [
          if (_bookingData != null && _bookingData!['status'] != 'CANCELLED')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: 'Cancel Booking',
              onPressed: _cancelBooking,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadBookingDetails)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFlightSection(),
                      const SizedBox(height: 24),
                      _buildPassengersSection(),
                      const SizedBox(height: 24),
                      _buildPaymentSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PNR: ${_bookingData!['pnr']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Booked on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(_bookingData!['created_at']))}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_bookingData!['status']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(_bookingData!['status'])),
              ),
              child: Text(
                _bookingData!['status'],
                style: TextStyle(
                  color: _getStatusColor(_bookingData!['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightSection() {
    final flight = _bookingData!['flight'];
    if (flight == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Flight Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      flight['flight_number'] ?? 'N/A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(
                      flight['status'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildRouteInfo(
                        flight['origin_airport']['code'],
                        flight['origin_airport']['city'],
                        flight['departure_time'],
                      ),
                    ),
                    const Icon(Icons.flight_takeoff, color: Colors.blue),
                    Expanded(
                      child: _buildRouteInfo(
                        flight['destination_airport']['code'],
                        flight['destination_airport']['city'],
                        flight['arrival_time'],
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(String code, String city, String time, {TextAlign textAlign = TextAlign.left}) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(city, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          DateFormat('HH:mm').format(DateTime.parse(time)),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          DateFormat('MMM dd').format(DateTime.parse(time)),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPassengersSection() {
    final tickets = _bookingData!['tickets'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tickets.map((ticket) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(ticket['passenger_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ticket: ${ticket['ticket_number']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Seat: ${ticket['seat_number'] ?? 'TBA'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final payments = _bookingData!['payments'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No payment records found'),
            ),
          )
        else
          ...payments.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${(p['amount'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p['status'] == 'PAID' ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p['status'],
                              style: TextStyle(
                                color: p['status'] == 'PAID' ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildPaymentInfoRow('Method', p['method']),
                      _buildPaymentInfoRow('Transaction ID', p['transaction_id'] ?? 'N/A'),
                      _buildPaymentInfoRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(p['created_at']))),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildPaymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Colors.green;
      case 'HOLD':
        return Colors.orange;
      case 'CANCELLED':
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
