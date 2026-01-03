import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'payment_viewmodel.dart';
import '../../../models/payment_model.dart' as models;

class PaymentView extends StackedView<PaymentViewModel> {
  final String bookingId;

  const PaymentView({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, PaymentViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            RadioListTile<models.PaymentMethod>(
              title: const Text('Credit Card'),
              value: models.PaymentMethod.card,
              groupValue: viewModel.selectedMethod,
              onChanged: viewModel.setPaymentMethod,
            ),
            RadioListTile<models.PaymentMethod>(
              title: const Text('Apple Pay'),
              value: models.PaymentMethod.applePay,
              groupValue: viewModel.selectedMethod,
              onChanged: viewModel.setPaymentMethod,
            ),
            RadioListTile<models.PaymentMethod>(
              title: const Text('Google Pay'),
              value: models.PaymentMethod.googlePay,
              groupValue: viewModel.selectedMethod,
              onChanged: viewModel.setPaymentMethod,
            ),
            const SizedBox(height: 24),
            
            // Success Message
            if (viewModel.paymentSuccess && viewModel.booking != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment Successful!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.booking!.pnr.isNotEmpty) ...[
                        Text(
                          'PNR: ${viewModel.booking!.pnr}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Booking Status: ${viewModel.booking!.status.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your booking has been confirmed. Seat holds have been released.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Error Message
            if (viewModel.hasError && !viewModel.paymentSuccess)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage ?? 'An error occurred',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: viewModel.paymentSuccess
                    ? null
                    : (viewModel.selectedMethod != null
                        ? (viewModel.isBusy ? null : viewModel.processPayment)
                        : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.paymentSuccess
                      ? Colors.grey.shade300
                      : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: viewModel.isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : viewModel.paymentSuccess
                        ? const Text('Payment Completed',
                            style: TextStyle(fontSize: 18))
                        : const Text('Process Payment',
                            style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  PaymentViewModel viewModelBuilder(BuildContext context) =>
      PaymentViewModel(bookingId: bookingId);
}

