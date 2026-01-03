import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/payments_api.dart';
import '../../shared/api/bookings_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class PaymentPage extends StatefulWidget {
  final String bookingPnr; // Changed from bookingId to PNR

  const PaymentPage({super.key, required this.bookingPnr});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final ApiClient _apiClient;
  late final PaymentsApi _paymentsApi;
  late final BookingsApi _bookingsApi;
  
  Booking? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  PaymentMethod _selectedMethod = PaymentMethod.CARD;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _paymentsApi = PaymentsApi(_apiClient);
    _bookingsApi = BookingsApi(_apiClient);
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _bookingsApi.getBookingByPnr(widget.bookingPnr);
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

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      await _paymentsApi.processPayment(
        bookingId: _booking!.id,
        method: _selectedMethod.name,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.bookingSuccess,
          arguments: _booking!.id,
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seats are held for 10 minutes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Complete payment to confirm your booking',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_booking != null) ...[
                      _buildInfoRow('PNR', _booking!.pnr),
                      _buildInfoRow('Passengers', '${_booking!.tickets?.length ?? 0}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_booking!.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(
              PaymentMethod.CARD,
              Icons.credit_card,
              'Credit/Debit Card',
            ),
            _buildPaymentMethodCard(
              PaymentMethod.APPLE_PAY,
              Icons.apple,
              'Apple Pay',
            ),
            _buildPaymentMethodCard(
              PaymentMethod.GOOGLE_PAY,
              Icons.payment,
              'Google Pay',
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Pay \$${_booking?.totalPrice.toStringAsFixed(2) ?? '0.00'}',
              onPressed: _processPayment,
              isLoading: _isProcessing,
              icon: Icons.lock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedMethod == method;
    
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMethod = value);
                  }
                },
              ),
            ],
          ),
        ),
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
}
