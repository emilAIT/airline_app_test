import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
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
      final response = await apiService.getMyPayments();
      
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
          _errorMessage = 'Failed to load payment history';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadPayments)
              : _payments.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No Payments Found',
                      message: 'Your payment history will appear here once you complete a booking.',
                      icon: Icons.payments_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'];
    final date = DateTime.parse(payment['created_at']).toLocal();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: \$${payment['amount'].toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                _buildStatusChip(status),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Transaction ID', payment['transaction_id']),
            _buildDetailRow('Method', payment['method']),
            _buildDetailRow('Booking ID', payment['booking_id'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    if (status == 'PAID') {
      chipColor = Colors.green[100]!;
    } else if (status == 'PENDING') {
      chipColor = Colors.orange[100]!;
    } else {
      chipColor = Colors.red[100]!;
    }
    
    return Chip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: status == 'PAID' ? Colors.green[900] : (status == 'PENDING' ? Colors.orange[900] : Colors.red[900]),
        ),
      ),
      backgroundColor: chipColor,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
