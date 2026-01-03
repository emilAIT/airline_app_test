import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/booking/domain/entities/booking.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_state.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_event.dart';
import 'package:ait_airlines/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';


class PaymentPage extends StatefulWidget {
  final Booking booking;

  const PaymentPage({super.key, required this.booking});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum PaymentMethod { card, googlePay, paypal }

class _PaymentPageState extends State<PaymentPage> {
  late Timer _timer;
  int _secondsRemaining = 0;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Вычисляем оставшееся время на основе времени создания брони
    // Бронь истекает через 10 минут после создания
    _calculateRemainingTime();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        _showExpiredDialog();
      }
    });
  }

  void _calculateRemainingTime() {
    // Время создания брони
    final createdAt = widget.booking.createdAt;
    // Время истечения (10 минут после создания)
    final expirationTime = createdAt.add(const Duration(minutes: 10));
    // Текущее время
    final now = DateTime.now();
    
    // Вычисляем оставшееся время в секундах
    final remaining = expirationTime.difference(now);
    _secondsRemaining = remaining.inSeconds;
    
    // Если время уже истекло, устанавливаем 0
    if (_secondsRemaining < 0) {
      _secondsRemaining = 0;
    }
    
    // Ограничиваем максимум 10 минутами (на случай если время создания в будущем)
    if (_secondsRemaining > 600) {
      _secondsRemaining = 600;
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Таймер всегда создаётся, поэтому можно безопасно отменить
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Expired'),
        content: const Text('Your 10-minute payment window has closed. Please try booking again.'),
        actions: [
          TextButton(
            onPressed: () {
              // Таймер уже отменён в _showExpiredDialog, но на всякий случай
              if (_timer.isActive) _timer.cancel();
              navigateToHome(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, не истекла ли бронь при каждом обновлении
    if (_secondsRemaining <= 0 && widget.booking.status == 'pending' && _timer.isActive) {
      // Если время истекло, показываем диалог
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _timer.cancel();
          _showExpiredDialog();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              navigateToHome(context);
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => navigateToHome(context),
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showSuccessOverlay();
          } else if (state is BookingError) {
            // Проверяем, не истекла ли бронь
            if (state.message.toLowerCase().contains('expired') || 
                state.message.toLowerCase().contains('истек')) {
              if (_timer.isActive) {
                _timer.cancel();
              }
              _showExpiredDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
              );
            }
          }
        },
        child: Stack(
          children: [
            // Background Gradient
            Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
            ),
            
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Column(
                children: [
                  _buildTimerCard(),
                  const SizedBox(height: 24),
                  _buildBookingSummaryCard(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSelector(),
                  const SizedBox(height: 24),
                  _buildPaymentForm(),
                  const SizedBox(height: 40),
                  _buildPayButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          const Text('Window closes in ', style: TextStyle(color: Colors.white70)),
          Text(
            _formatTime(_secondsRemaining),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${widget.booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        widget.booking.bookingReference,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                Row(
                  children: [
                    _buildSummaryItem(Icons.flight_outlined, 'Flight', widget.booking.flight?.flightNumber ?? 'KZ101'),
                    const Spacer(),
                    _buildSummaryItem(Icons.people_outline, 'Passengers', widget.booking.passengersCount.toString()),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 14, color: Colors.green),
                SizedBox(width: 8),
                Text('Secure SSL Encrypted Payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'PAYMENT METHOD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 1),
            ),
          ),
          _buildPaymentMethodOption(
            PaymentMethod.card,
            'Bank Card',
            Icons.credit_card,
            const Color(0xFF1A1A2E),
          ),
          _buildPaymentMethodOption(
            PaymentMethod.googlePay,
            'Google Pay',
            Icons.account_balance_wallet,
            const Color(0xFF4285F4),
          ),
          _buildPaymentMethodOption(
            PaymentMethod.paypal,
            'PayPal',
            Icons.payment,
            const Color(0xFF0070BA),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, String label, IconData icon, Color iconColor) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: iconColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedPaymentMethod == PaymentMethod.card) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CARD DETAILS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                _buildTextField(_cardNumberController, 'Card Number', Icons.credit_card, obscure: false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_expiryController, 'Expiry (MM/YY)', Icons.date_range, obscure: false)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_cvvController, 'CVV', Icons.lock_outline, obscure: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_selectedPaymentMethod == PaymentMethod.googlePay) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GOOGLE PAY DETAILS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Google Account Email', Icons.email, obscure: false),
            const SizedBox(height: 8),
            const Text(
              'You will be redirected to Google Pay to complete the payment.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (_selectedPaymentMethod == PaymentMethod.paypal) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAYPAL DETAILS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'PayPal Email', Icons.email, obscure: false),
            const SizedBox(height: 8),
            const Text(
              'You will be redirected to PayPal to complete the payment.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A1A2E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final isLoading = state is BookingLoading;
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isLoading ? null : () {
              // Validate based on selected payment method
              if (_selectedPaymentMethod == PaymentMethod.card) {
                if (_cardNumberController.text.isEmpty || 
                    _expiryController.text.isEmpty || 
                    _cvvController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all card details'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                context.read<BookingBloc>().add(
                  ProcessPaymentRequested(
                    bookingId: widget.booking.id,
                    cardData: {
                      'card_number': _cardNumberController.text,
                      'expiry': _expiryController.text,
                      'cvv': _cvvController.text,
                    },
                  ),
                );
              } else if (_selectedPaymentMethod == PaymentMethod.googlePay) {
                if (_emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your Google account email'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                context.read<BookingBloc>().add(
                  ProcessPaymentRequested(
                    bookingId: widget.booking.id,
                    cardData: {
                      'payment_method': 'google_pay',
                      'email': _emailController.text,
                    },
                  ),
                );
              } else if (_selectedPaymentMethod == PaymentMethod.paypal) {
                if (_emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your PayPal email'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                context.read<BookingBloc>().add(
                  ProcessPaymentRequested(
                    bookingId: widget.booking.id,
                    cardData: {
                      'payment_method': 'paypal',
                      'email': _emailController.text,
                    },
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFE94560).withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Confirm Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text('Payment Success!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your flight is successfully booked.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Refresh notifications instantly
                    context.read<NotificationBloc>().add(const LoadNotifications(refresh: true));
                    navigateToHome(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
