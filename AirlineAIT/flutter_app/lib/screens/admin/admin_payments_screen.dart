import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getAllPayments();
      
      if (mounted) {
        setState(() {
          _payments = response.data as List;
          // Sort by creation date descending
          _payments.sort((a, b) {
            final dateA = DateTime.parse(a['created_at']);
            final dateB = DateTime.parse(b['created_at']);
            return dateB.compareTo(dateA);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load all payments';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadPayments)
              : _payments.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No Payments',
                      message: 'There are no payment records in the system.',
                      icon: Icons.payments_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return _buildPaymentCard(payment);
                      },
                    ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'];
    final date = DateTime.parse(payment['created_at']).toLocal();
    final user = payment['user_info'];
    final flight = payment['flight_info'];
    final booking = payment['booking_info'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${payment['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            _buildStatusChip(status),
          ],
        ),
        subtitle: Text('User: ${user['email']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('PAYMENT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                _buildDetailRow('Transaction ID', payment['transaction_id']),
                _buildDetailRow('Method', payment['method']),
                
                const SizedBox(height: 12),
                const Text('BOOKING & FLIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                _buildDetailRow('PNR', booking['pnr']),
                _buildDetailRow('Flight', flight['flight_number']),
                _buildDetailRow('Route', '${flight['origin']} → ${flight['destination']}'),
                _buildDetailRow('Departure', DateFormat('MMM dd, HH:mm').format(DateTime.parse(flight['departure_time']).toLocal())),
                
                const SizedBox(height: 12),
                const Text('USER INFO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                _buildDetailRow('Email', user['email']),
                _buildDetailRow('Role', user['role']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    if (status == 'PAID') {
      chipColor = Colors.green;
    } else if (status == 'PENDING') {
      chipColor = Colors.orange;
    } else {
      chipColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        border: Border.all(color: chipColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: chipColor),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
