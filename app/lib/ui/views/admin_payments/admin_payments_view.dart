import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'admin_payments_viewmodel.dart';
import '../../../models/payment_model.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminPaymentsView extends StackedView<AdminPaymentsViewModel> {
  const AdminPaymentsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminPaymentsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Payments Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadPayments,
          tooltip: 'Refresh',
        ),
      ],
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading payments',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.neutral600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: viewModel.loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 64, color: AppTheme.neutral400),
                          const SizedBox(height: 16),
                          Text(
                            'No payments found',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.neutral600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: viewModel.loadPayments,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadPayments,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.dark700,
                              border: Border(
                                bottom: BorderSide(color: AppTheme.dark600, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pink600.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.info_outline_rounded,
                                      color: AppTheme.pink600, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Total payments: ${viewModel.payments.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: viewModel.payments.length,
                              itemBuilder: (context, index) {
                                final payment = viewModel.payments[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dark700,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.dark600, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _getStatusColor(payment.status),
                                                    _getStatusColor(payment.status).withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getStatusColor(payment.status).withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _getStatusIcon(payment.status),
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Payment ${payment.id.substring(0, 8)}...',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        letterSpacing: -0.5),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 12, vertical: 6),
                                                        decoration: AppTheme.getBadgeDecoration(_getStatusColor(payment.status)),
                                                        child: Text(
                                                          _getStatusText(payment.status),
                                                          style: TextStyle(
                                                            color: _getStatusColor(payment.status),
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 11,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 12, vertical: 6),
                                                        decoration: AppTheme.getBadgeDecoration(AppTheme.pink600),
                                                        child: Text(
                                                          _getMethodText(payment.method),
                                                          style: TextStyle(
                                                            color: AppTheme.pink600,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 11,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: AppTheme.dark600,
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dark600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              _buildInfoRow(
                                                Icons.confirmation_number_rounded,
                                                'Booking ID',
                                                payment.bookingId,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildInfoRow(
                                                Icons.calendar_today_rounded,
                                                'Created',
                                                DateFormat('MMM dd, yyyy • HH:mm').format(payment.createdAt),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => viewModel.viewPaymentDetails(context, payment),
                                              icon: const Icon(Icons.visibility_rounded, size: 20),
                                              label: const Text('View Details', style: TextStyle(fontSize: 15)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.pink600,
                                                side: BorderSide(color: AppTheme.pink600, width: 2),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                              ),
                                            ),
                                            if (payment.status == PaymentStatus.pending) ...[
                                              const SizedBox(width: 12),
                                              ElevatedButton.icon(
                                                onPressed: () => viewModel.showUpdateStatusDialog(context, payment),
                                                icon: const Icon(Icons.update_rounded, size: 20),
                                                label: const Text('Update Status', style: TextStyle(fontSize: 15)),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.pink600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppTheme.success;
      case PaymentStatus.pending:
        return AppTheme.warning;
      case PaymentStatus.failed:
        return AppTheme.error;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.failed:
        return Icons.error;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.failed:
        return 'FAILED';
    }
  }

  String _getMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.applePay:
        return 'APPLE PAY';
      case PaymentMethod.googlePay:
        return 'GOOGLE PAY';
    }
  }

  @override
  AdminPaymentsViewModel viewModelBuilder(BuildContext context) =>
      AdminPaymentsViewModel();

  @override
  void onViewModelReady(AdminPaymentsViewModel viewModel) {
    viewModel.loadPayments();
  }
}
