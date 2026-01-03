// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';

class BookingPendingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingPendingScreen({super.key, required this.booking});

  @override
  State<BookingPendingScreen> createState() => _BookingPendingScreenState();
}

class _BookingPendingScreenState extends State<BookingPendingScreen> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 10);
  bool _expired = false;
  bool _paying = false;
  String? _paymentStatus;
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  DateTime? _parseServerUtc(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final hasTz = s.endsWith('Z') || s.contains('+') || RegExp(r'-\d\d:\d\d$').hasMatch(s);
    final parsed = DateTime.tryParse(hasTz ? s : '${s}Z');
    return parsed?.toUtc();
  }

  void _initCountdown() {
    // Prefer server-provided expiry so reopening screen doesn't reset the hold.
    final heldUntilRaw = widget.booking['seats_held_until']?.toString();
    final heldUntil = _parseServerUtc(heldUntilRaw);
    if (heldUntil != null) {
      final now = DateTime.now().toUtc();
      final diff = heldUntil.difference(now);
      _remaining = diff.isNegative ? Duration.zero : diff;
      _expired = _remaining == Duration.zero;
    } else {
      // Fallback: start from 10 minutes on client.
      _remaining = const Duration(minutes: 10);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _remaining - const Duration(seconds: 1);
      setState(() {
        _remaining = next.isNegative ? Duration.zero : next;
      });

      if (_remaining == Duration.zero) {
        _timer?.cancel();
        _onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _onExpired() async {
    if (!mounted) return;
    setState(() => _expired = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Return to the root (MainScreen) so bottom navigation is visible.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.booking['id']?.toString() ?? '';
    final pnr = widget.booking['pnr']?.toString() ?? '';
    final status = widget.booking['status']?.toString() ?? '';
    final canPay = !_expired && !_paying && pnr.isNotEmpty && status != 'CONFIRMED' && _paymentStatus != 'PAID';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Бронирование создано',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Завершите оплату в течение',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: ZaKuColors.darkGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _format(_remaining),
                  style: GoogleFonts.montserrat(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: ZaKuColors.burgundy,
                  ),
                ),
                const SizedBox(height: 24),
                if (pnr.isNotEmpty)
                  Text(
                    'PNR: $pnr',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                if (bookingId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: $bookingId',
                    style: GoogleFonts.montserrat(color: ZaKuColors.darkGrey),
                  ),
                ],

                const Spacer(),
                if (_paymentError != null) ...[
                  Text(
                    _paymentError!,
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canPay ? () => _chooseAndPay(pnr) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZaKuColors.gold,
                      foregroundColor: ZaKuColors.burgundy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _paying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ZaKuColors.burgundy),
                          )
                        : Text(
                            _paymentStatus == 'PAID' ? 'Оплачено' : 'Оплатить',
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_paymentStatus == 'PAID')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Return to the root (MainScreen) so bottom navigation is visible.
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text('К поиску рейсов', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
          if (_expired)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Session Expired\nSeats Released',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Возвращаем к поиску рейсов…',
                      style: GoogleFonts.montserrat(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseAndPay(String pnr) async {
    if (!mounted) return;

    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Способ оплаты'),
        content: const Text('Выберите способ оплаты (mock).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'CARD'),
            child: const Text('CARD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'APPLE_PAY'),
            child: const Text('APPLE_PAY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'GOOGLE_PAY'),
            child: const Text('GOOGLE_PAY'),
          ),
        ],
      ),
    );

    if (method == null || method.trim().isEmpty) return;
    await _pay(pnr, method);
  }

  Future<void> _pay(String pnr, String method) async {
    if (!mounted) return;
    setState(() {
      _paying = true;
      _paymentError = null;
    });

    try {
      final result = await ApiService.confirmPaymentByPnr(
        bookingPnr: pnr,
        paymentMethod: method,
      );

      if (!mounted) return;
      if (result == null) {
        setState(() {
          _paymentError = 'Не удалось выполнить оплату. Попробуйте ещё раз.';
        });
        return;
      }

      final status = result['status']?.toString();
      final bookingStatus = result['booking_status']?.toString();
      setState(() {
        _paymentStatus = status;
      });

      if (bookingStatus != null && bookingStatus.isNotEmpty) {
        widget.booking['status'] = bookingStatus;
      }

      if (status == 'PAID') {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оплата прошла успешно!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _paymentError = 'Оплата не прошла: ${status ?? 'FAILED'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paymentError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }
}
