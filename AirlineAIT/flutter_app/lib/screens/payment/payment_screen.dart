import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../bookings/my_trips_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  String? _errorMessage;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  dynamic _booking;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'CARD', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'value': 'APPLE_PAY', 'label': 'Apple Pay', 'icon': Icons.apple},
    {'value': 'GOOGLE_PAY', 'label': 'Google Pay', 'icon': Icons.android},
  ];

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getBookingDetails(widget.bookingId);
      
      if (mounted) {
        setState(() {
          _booking = response.data;
          _isLoading = false;
        });
        _checkExpiration();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load booking details';
          _isLoading = false;
        });
      }
    }
  }

  void _checkExpiration() {
    if (_booking == null || _booking['status'] != 'HOLD') return;

    final nowLocal = DateTime.now();
    
    DateTime serverTime;
    if (_booking['server_time'] != null) {
      serverTime = DateTime.parse(_booking['server_time']);
    } else {
      serverTime = nowLocal;
    }

    DateTime expiresAt;
    if (_booking['expires_at'] != null) {
      expiresAt = DateTime.parse(_booking['expires_at']);
    } else {
      String createdAt = _booking['created_at'];
      expiresAt = DateTime.parse(createdAt).add(const Duration(minutes: 10));
    }

    final drift = serverTime.difference(nowLocal);
    final adjustedNow = nowLocal.add(drift);

    if (adjustedNow.isAfter(expiresAt)) {
      setState(() {
        _errorMessage = 'This booking has expired.';
        _timeLeft = Duration.zero;
      });
    } else {
      _timeLeft = expiresAt.difference(adjustedNow);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _errorMessage = 'This booking has expired.';
        }
      });
    });
  }

  Future<void> _processPayment() async {
    if (_timeLeft.inSeconds <= 0 && _booking?['status'] == 'HOLD') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot pay for an expired booking')),
      );
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.processPayment({
        'booking_id': widget.bookingId,
        'method': _selectedMethod,
      });

      if (mounted) {
        _timer?.cancel();
        // Navigate back to home screen (which contains My Trips with bottom nav)
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! View your booking in My Trips.'), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final backendMessage = e.response?.data?['detail']?.toString();
        setState(() {
          if (backendMessage != null && backendMessage.toLowerCase().contains('expired')) {
            _errorMessage = 'Payment failed: Booking has expired';
          } else {
            _errorMessage = backendMessage ?? 'Payment failed. Please try again.';
          }
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? The held seats will be released.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, Keep It')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.cancelBooking(widget.bookingId);
      if (mounted) {
        _timer?.cancel();
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled successfully')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to cancel booking: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: (_isProcessing || _isLoading)
          ? LoadingWidget(message: _isLoading ? 'Loading booking...' : 'Processing payment...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_timeLeft.inSeconds > 0)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Time remaining to pay: ${_formatDuration(_timeLeft)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your seat is reserved for 10 minutes. Complete payment before the timer expires.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Payment Method',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ..._paymentMethods.map((method) => RadioListTile<String>(
                                title: Text(method['label'] as String),
                                value: method['value'] as String,
                                groupValue: _selectedMethod,
                                onChanged: _timeLeft.inSeconds > 0 || _booking?['status'] != 'HOLD' 
                                  ? (value) {
                                      setState(() {
                                        _selectedMethod = value;
                                      });
                                    }
                                  : null,
                                secondary: Icon(method['icon'] as IconData),
                              )),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_errorMessage!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_timeLeft.inSeconds > 0 || _booking?['status'] != 'HOLD') && !_isProcessing
                        ? _processPayment
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Pay Now'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: !_isProcessing ? _cancelBooking : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: This is a mock payment. No actual charges will be made.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

