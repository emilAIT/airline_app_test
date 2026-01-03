import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'card_payment_form.dart';
import 'glass_card.dart';
import 'glow_button.dart';

class CancellationDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback onCancelled;

  const CancellationDialog({
    super.key,
    required this.booking,
    required this.onCancelled,
  });

  @override
  State<CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<CancellationDialog> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _cancelInfo;
  String? _error;
  
  bool _isCardValid = false;
  Map<String, String> _cardDetails = {};

  // Determine refund method from original payment
  String get _refundMethod {
    if (widget.booking.payment != null) {
      return widget.booking.payment!['method'] ?? 'CARD';
    }
    return 'CARD';
  }

  bool get _isApplePay => _refundMethod == 'APPLE_PAY';

  @override
  void initState() {
    super.initState();
    _fetchCancelInfo();
  }

  Future<void> _fetchCancelInfo() async {
    try {
      final info = await _api.getCancellationInfo(widget.booking.id);
      if (mounted) {
        setState(() {
          _cancelInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processCancellation() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _api.cancelBookingWithRefund(
        widget.booking.id,
        method: _refundMethod,
        cardNumber: _isApplePay ? null : _cardDetails['cardNumber'],
        cardHolder: _isApplePay ? null : _cardDetails['cardHolder'],
        expiryMonth: _isApplePay ? null : int.tryParse(_cardDetails['expiry']?.split('/')[0] ?? '0'),
        expiryYear: _isApplePay ? null : int.tryParse(_cardDetails['expiry']?.split('/')[1] ?? '0'),
        cvv: _isApplePay ? null : _cardDetails['cvv'],
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Booking cancelled successfully'),
            backgroundColor: EldiyarTheme.successGreen,
          ),
        );
        widget.onCancelled();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancellation Failed: ${e.toString()}'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  bool get _canConfirm {
    if (_isProcessing) return false;
    if (_isApplePay) return true; // No form needed
    return _isCardValid;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      color: EldiyarTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: EldiyarTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: EldiyarTheme.primaryBlue),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: EldiyarTheme.errorRed))
              else if (_cancelInfo != null) ...[
                if (_cancelInfo!['allowed'] == false) ...[
                  _buildNotAllowedMessage(_cancelInfo!['description'] ?? 'Cancellation not allowed'),
                ] else ...[
                  // Refund Summary
                  _buildRefundSummary(_cancelInfo!),
                  const SizedBox(height: 16),

                  // Conditional: Card Form OR Apple Pay Message
                  if (_isApplePay) ...[
                    _buildApplePayRefundMessage(),
                  ] else ...[
                    const Text(
                      'Enter Card for Refund',
                      style: TextStyle(
                        color: EldiyarTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CardPaymentForm(
                      onValidationChanged: (isValid) {
                        setState(() => _isCardValid = isValid);
                      },
                      onDetailsChanged: (details) {
                        _cardDetails = details;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: GlowButton(
                      label: _isProcessing ? 'Processing...' : 'Confirm Cancellation',
                      icon: Icons.cancel_presentation,
                      glowColor: EldiyarTheme.errorRed,
                      onPressed: _canConfirm ? _processCancellation : null,
                    ),
                  ),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotAllowedMessage(String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EldiyarTheme.errorRed.withValues(alpha: 0.1),
        border: Border.all(color: EldiyarTheme.errorRed),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EldiyarTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: const TextStyle(color: EldiyarTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSummary(Map<String, dynamic> info) {
    final double amount = (info['refund_amount'] as num).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EldiyarTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EldiyarTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info['description'],
            style: const TextStyle(color: EldiyarTheme.primaryBlue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Refund Amount:', style: TextStyle(color: EldiyarTheme.textSecondary)),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: EldiyarTheme.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplePayRefundMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.apple, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Refund to Apple Pay',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your refund will be automatically processed back to your original Apple Pay payment method.',
                  style: TextStyle(color: EldiyarTheme.textPrimary.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
