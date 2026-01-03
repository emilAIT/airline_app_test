// FILE: payment_screen.dart
// PURPOSE: Handles payment processing for flight bookings
// SCOPE: 100% BACKEND-MOCKED payment (no real payment SDKs)
// WORKS ON: Web, iOS Simulator, Android Emulator

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/card_payment_form.dart';
import '../theme/app_theme.dart';
import 'my_trips_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _api = ApiService();
  String? _selectedMethod;
  bool _isProcessing = false;
  bool _isCardValid = false;
  Map<String, dynamic>? _booking;

  final List<String> _paymentMethods = ['CARD', 'APPLE_PAY', 'GOOGLE_PAY'];

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  // FUNCTION: _loadBooking
  // PURPOSE: Fetches booking details from backend
  // CALLED BY: initState
  Future<void> _loadBooking() async {
    try {
      final booking = await _api.getBooking(widget.bookingId);
      setState(() => _booking = booking);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading booking: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  // FUNCTION: _processPayment
  // PURPOSE: Sends mock payment request to backend (100% simulated)
  // NOTE: Works identically on Web, iOS, Android - no real SDKs used
  // DEPENDS ON: ApiService.processPayment
  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: EldiyarTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // MOCK PAYMENT - Backend simulates success for all methods
      final payment = await _api.processPayment(
        widget.bookingId,
        _selectedMethod!,
      );

      if (mounted) {
        _showPaymentReceipt(payment);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: EldiyarTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // FUNCTION: _showPaymentReceipt
  // PURPOSE: Displays success dialog and navigates to My Trips
  void _showPaymentReceipt(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: EldiyarTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: EldiyarTheme.successGreen,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Payment Successful!',
                style: TextStyle(
                  color: EldiyarTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction ID:',
                style: TextStyle(
                  color: EldiyarTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                payment['transaction_id'] ?? 'N/A',
                style: const TextStyle(
                  color: EldiyarTheme.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount:',
                    style: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  Text(
                    '\$${(payment['amount'] is num ? payment['amount'] : double.parse(payment['amount'].toString())).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: EldiyarTheme.accentTeal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Method:',
                    style: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  Text(
                    payment['method'].toString().replaceAll('_', ' '),
                    style: const TextStyle(
                      color: EldiyarTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: GlowButton(
              label: 'View My Trips',
              icon: Icons.flight_takeoff,
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyTripsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // FUNCTION: _getPaymentIcon
  // PURPOSE: Returns appropriate icon for each payment method
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'CARD':
        return Icons.credit_card;
      case 'APPLE_PAY':
        return Icons.apple;
      case 'GOOGLE_PAY':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: _booking == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      EldiyarTheme.primaryBlue,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: EldiyarTheme.primaryBlue,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: EldiyarTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Booking Summary
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number,
                                  color: EldiyarTheme.primaryBlue,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PNR: ${_booking!['pnr']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: EldiyarTheme.primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        'Status: ${_booking!['status']}',
                                        style: const TextStyle(
                                          color: EldiyarTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Text(
                              'Flight: ${_booking!['flight']['flight_number']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: EldiyarTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${_booking!['flight']['origin']['code']} → ${_booking!['flight']['destination']['code']}',
                              style: const TextStyle(
                                color: EldiyarTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Passengers: ${(_booking!['tickets'] as List).length}',
                              style: const TextStyle(
                                color: EldiyarTheme.textSecondary,
                              ),
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '\$${(_booking!['flight']['base_price'] * (_booking!['tickets'] as List).length).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: EldiyarTheme.accentTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Payment Methods
                      Text(
                        'Select Payment Method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      ..._paymentMethods.map((method) {
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () => setState(() => _selectedMethod = method),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedMethod == method
                                      ? EldiyarTheme.primaryBlue.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedMethod == method
                                        ? EldiyarTheme.primaryBlue
                                        : EldiyarTheme.primaryBlue.withOpacity(0.3),
                                    width: _selectedMethod == method ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  _getPaymentIcon(method),
                                  color: _selectedMethod == method
                                      ? EldiyarTheme.primaryBlue
                                      : EldiyarTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  method.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _selectedMethod == method
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _selectedMethod == method
                                        ? EldiyarTheme.primaryBlue
                                        : EldiyarTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (_selectedMethod == method)
                                const Icon(
                                  Icons.check_circle,
                                  color: EldiyarTheme.primaryBlue,
                                ),
                            ],
                          ),
                        );
                      }),
                      
                      // Card Payment Form (shown when CARD is selected)
                      if (_selectedMethod == 'CARD') ...[
                        const SizedBox(height: 24),
                        CardPaymentForm(
                          onValidationChanged: (valid) {
                            setState(() => _isCardValid = valid);
                          },
                        ),
                      ],
                      
                      // Mock Payment Info Banner
                      if (_selectedMethod != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: EldiyarTheme.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: EldiyarTheme.accentTeal.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: EldiyarTheme.accentTeal,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mock Payment Mode',
                                      style: TextStyle(
                                        color: EldiyarTheme.accentTeal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This is a demonstration system. Payment will be simulated automatically.',
                                      style: TextStyle(
                                        color: EldiyarTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Pay Now Button
                      SizedBox(
                        width: double.infinity,
                        child: GlowButton(
                          label: _isProcessing
                              ? 'Processing...'
                              : 'Pay Now (\$${_booking != null ? (_booking!['flight']['base_price'] * (_booking!['tickets'] as List).length).toStringAsFixed(2) : '0.00'})',
                          icon: Icons.lock,
                          onPressed: _isProcessing || (_selectedMethod == 'CARD' && !_isCardValid)
                              ? null
                              : _processPayment,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
