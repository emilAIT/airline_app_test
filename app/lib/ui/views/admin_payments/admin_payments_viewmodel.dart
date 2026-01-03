import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.locator.dart';
import '../../../services/payment_service.dart';
import '../../../models/payment_model.dart';

class AdminPaymentsViewModel extends BaseViewModel {
  final PaymentService _paymentService = PaymentService();
  final NavigationService _navigationService = locator<NavigationService>();

  List<PaymentPublic> _payments = [];
  List<PaymentPublic> get payments => _payments;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadPayments() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the new endpoint to get all payments directly
      _payments = await _paymentService.getAllPayments(limit: 200);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _payments = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void viewPaymentDetails(BuildContext context, PaymentPublic payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details - ${payment.id.substring(0, 8)}...'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Payment ID', payment.id),
              _buildDetailRow('Status', payment.status.name.toUpperCase()),
              _buildDetailRow('Method', payment.method.name.toUpperCase()),
              _buildDetailRow('Booking ID', payment.bookingId),
              _buildDetailRow('Idempotency Key', payment.idempotencyKey),
              _buildDetailRow(
                'Created',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(payment.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void showUpdateStatusDialog(BuildContext context, PaymentPublic payment) {
    showDialog<PaymentStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new status:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Paid'),
              leading: Radio<PaymentStatus>(
                value: PaymentStatus.paid,
                groupValue: null,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context, value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Failed'),
              leading: Radio<PaymentStatus>(
                value: PaymentStatus.failed,
                groupValue: null,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context, value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((status) async {
      if (status != null) {
        await updatePaymentStatus(context, payment, status);
      }
    });
  }

  Future<void> updatePaymentStatus(
      BuildContext context, PaymentPublic payment, PaymentStatus status) async {
    setBusy(true);
    try {
      await _paymentService.updatePaymentStatus(payment.id, status);
      await loadPayments();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment status updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }
}
