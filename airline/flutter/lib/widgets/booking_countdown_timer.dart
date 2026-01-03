// WIDGET: BookingCountdownTimer
// PURPOSE: Live countdown timer for bookings on hold
// SHOWS: Time remaining in MM:SS format
// CALLS: onExpired() when timer reaches zero

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookingCountdownTimer extends StatefulWidget {
  final DateTime holdUntil;
  final VoidCallback onExpired;

  const BookingCountdownTimer({
    super.key,
    required this.holdUntil,
    required this.onExpired,
  });

  @override
  State<BookingCountdownTimer> createState() => _BookingCountdownTimerState();
}

class _BookingCountdownTimerState extends State<BookingCountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.holdUntil.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      setState(() => _remaining = Duration.zero);
      _timer.cancel();
      widget.onExpired();
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _remaining.inMinutes < 2
            ? EldiyarTheme.errorRed.withOpacity(0.2)
            : EldiyarTheme.accentTeal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _remaining.inMinutes < 2
              ? EldiyarTheme.errorRed
              : EldiyarTheme.accentTeal,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _remaining.inMinutes < 2
                ? EldiyarTheme.errorRed
                : EldiyarTheme.accentTeal,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} remaining',
            style: TextStyle(
              color: _remaining.inMinutes < 2
                  ? EldiyarTheme.errorRed
                  : EldiyarTheme.accentTeal,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
