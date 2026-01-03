import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_countdown_timer.dart';

class PendingBookingBanner extends StatelessWidget {
  final List<dynamic> pendingBookings;
  final VoidCallback onPaymentPressed;
  final VoidCallback onDismiss;

  const PendingBookingBanner({
    super.key,
    required this.pendingBookings,
    required this.onPaymentPressed,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingBookings.isEmpty) return const SizedBox.shrink();

    final booking = pendingBookings[0];
    final flight = booking['flight'];
    var dateStr = booking['hold_until'];
    if (!dateStr.endsWith('Z')) dateStr += 'Z';
    final holdUntil = DateTime.parse(dateStr);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EldiyarTheme.accentTeal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EldiyarTheme.accentTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: EldiyarTheme.accentTeal.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: EldiyarTheme.accentTeal,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: EldiyarTheme.accentTeal,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: EldiyarTheme.textSecondary,
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${flight['flight_number']} - ${flight['origin']['code']} → ${flight['destination']['code']}',
            style: const TextStyle(
              fontSize: 14,
              color: EldiyarTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              BookingCountdownTimer(
                holdUntil: holdUntil,
                onExpired: () {
                  // Booking expired, refresh
                  onDismiss();
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onPaymentPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EldiyarTheme.accentTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Pay Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
