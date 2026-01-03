import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/flights/flight_details_screen.dart';
import '../screens/payment/payment_screen.dart';

class BookingCard extends StatefulWidget {
  final dynamic booking;
  final Function(int bookingId, String pnr)? onCancel;
  final Function(int ticketId)? onCheckIn;
  final Function(int ticketId)? onViewBoardingPass;
  final VoidCallback onRefresh;

  const BookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.onCheckIn,
    this.onViewBoardingPass,
    required this.onRefresh,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  String? _statusOverride;

  @override
  void initState() {
    super.initState();
    _checkExpiration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkExpiration() {
    final status = widget.booking['status'];
    if (status != 'HOLD') return;

    // Backend sends naive local time (Asia/Bishkek)
    final nowLocal = DateTime.now();
    
    DateTime serverTime;
    if (widget.booking['server_time'] != null) {
      serverTime = DateTime.parse(widget.booking['server_time']);
    } else {
      serverTime = nowLocal; // Fallback if server_time is missing
    }

    DateTime expiresAt;
    if (widget.booking['expires_at'] != null) {
      expiresAt = DateTime.parse(widget.booking['expires_at']);
    } else {
      // Fallback: created_at + 10 mins
      String createdAt = widget.booking['created_at'];
      expiresAt = DateTime.parse(createdAt).add(const Duration(minutes: 10));
    }

    // Calculate clock drift: offset = serverTime - nowLocal
    // If client is 1 min behind, serverTime is 10:01, nowLocal is 10:00 -> offset is +1 min
    final drift = serverTime.difference(nowLocal);
    
    // Adjusted current time for this client
    final adjustedNow = nowLocal.add(drift);

    if (adjustedNow.isAfter(expiresAt)) {
      if (mounted) {
        setState(() => _statusOverride = 'EXPIRED');
      }
      Future.delayed(const Duration(seconds: 2), widget.onRefresh);
    } else {
      _timeLeft = expiresAt.difference(adjustedNow);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _statusOverride = 'EXPIRED';
          widget.onRefresh();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    String createdAtStr = booking['created_at'];
    final createdDate = DateTime.parse(createdAtStr).toLocal();
    final bookingId = booking['id'];
    
    // Check if flight is cancelled to override status
    String? flightStatusOverride;
    if (booking['flight'] != null && booking['flight']['status'] == 'CANCELLED') {
      flightStatusOverride = 'FLIGHT CANCELLED';
    }

    final status = _statusOverride ?? flightStatusOverride ?? booking['status'];
    String statusLabel = status;
    Color statusColor;

    if (status == 'HOLD') {
      statusColor = Colors.orange.shade100;
      statusLabel = 'ON HOLD';
    } else if (status == 'CONFIRMED') {
      statusColor = Colors.green.shade100;
    } else if (status == 'CANCELLED' || status == 'EXPIRED' || status == 'FLIGHT CANCELLED') {
      statusColor = Colors.grey.shade300;
      statusLabel = status == 'EXPIRED' ? 'EXPIRED' : (status == 'FLIGHT CANCELLED' ? 'FLIGHT CANCELLED' : 'CANCELLED');
      if (status == 'FLIGHT CANCELLED') statusColor = Colors.red.shade100;
    } else {
      statusColor = Colors.grey.shade200;
    }

    if (status == 'EXPIRED') {
       return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PNR: ${booking['pnr']}', style: Theme.of(context).textTheme.titleMedium),
                  Chip(label: const Text('EXPIRED', style: TextStyle(fontSize: 12)), backgroundColor: Colors.grey.shade300),
                ],
               ),
               const SizedBox(height: 8),
               const Text(
                 'This booking has expired. The seat has been released.',
                 style: TextStyle(color: Colors.red),
               ),
            ],
          ),
        ),
       );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlightDetailsScreen(flightId: booking['flight_id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PNR: ${booking['pnr']}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(createdDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(statusLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: statusColor,
                      ),
                      if (status == 'HOLD' && _timeLeft.inSeconds > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(_timeLeft),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (booking['tickets'] != null && booking['tickets'].isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                ...booking['tickets'].map<Widget>((ticket) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket['passenger_name'] ?? 'Unknown Passenger',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Seat: ${ticket['seat_number'] ?? 'TBA'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          if (status == 'CONFIRMED' && booking['flight'] != null) () {
                            final flight = booking['flight'];
                            final fStatus = flight['status'];
                            final dep = DateTime.parse(flight['departure_time']);
                            final now = DateTime.now();
                            final checkInOpen = dep.subtract(const Duration(hours: 24));
                            final checkInClose = dep.subtract(const Duration(minutes: 60));
                            
                            // Classification helpers
                            final isCheckedIn = ticket['is_checked_in'] == true;
                            final isPast = fStatus == 'DEPARTED' || fStatus == 'LANDED' || fStatus == 'CANCELLED';
                            final isBoarding = fStatus == 'BOARDING';
                            final isWindowOpen = now.isAfter(checkInOpen) && now.isBefore(checkInClose);

                            if (isPast) {
                              String label = 'Flight Departed';
                              if (fStatus == 'LANDED') label = 'Flight Landed';
                              if (fStatus == 'CANCELLED') label = 'Flight Cancelled';
                              return Text(
                                label,
                                style: TextStyle(fontSize: 12, color: fStatus == 'CANCELLED' ? Colors.grey : Colors.red),
                              );
                            }

                            if (isCheckedIn && widget.onViewBoardingPass != null) {
                               return OutlinedButton.icon(
                                onPressed: () => widget.onViewBoardingPass!(ticket['id']),
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Boarding Pass'),
                              );
                            } else if (isWindowOpen && widget.onCheckIn != null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => widget.onCheckIn!(ticket['id']),
                                    child: const Text('Check In'),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Check-in closes 1 hour before departure',
                                    style: TextStyle(fontSize: 10, color: Colors.orange),
                                  ),
                                ],
                              );
                            } else if (now.isBefore(checkInOpen)) {
                              return const Text(
                                'Check-in starts 24 hours before departure',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              );
                            } else if (now.isAfter(checkInClose) && !isPast && !isCheckedIn) {
                              return const Text(
                                'Check-in Closed',
                                style: TextStyle(fontSize: 12, color: Colors.red),
                              );
                            } else {
                              return const Text(
                                'Flight Departed',
                                style: TextStyle(fontSize: 12, color: Colors.red),
                              );
                            }
                          }(),
                        ],
                      ),
                    )),
              ],
              
              if (status == 'HOLD') ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel != null ? () => widget.onCancel!(bookingId, booking['pnr']) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(bookingId: bookingId),
                            ),
                          ).then((_) => widget.onRefresh());
                        },
                        child: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              ],

              if (status == 'CONFIRMED' && widget.onCancel != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                      // Disable cancel if check-in started or flight departed
                      if (_canCancel(booking))
                          TextButton.icon(
                            onPressed: () => widget.onCancel!(bookingId, booking['pnr']),
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                          ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canCancel(dynamic booking) {
    // 1. Check flight status
    if (booking['flight'] != null) {
      final status = booking['flight']['status'];
      if (status == 'DEPARTED' || status == 'LANDED' || status == 'BOARDING' || status == 'CANCELLED') {
        return false;
      }

      // 2. Check time window (60 mins before departure)
      try {
        final dep = DateTime.parse(booking['flight']['departure_time']);
        final now = DateTime.now();
        final cutoff = dep.subtract(const Duration(minutes: 60));
        if (now.isAfter(cutoff)) {
          return false;
        }
      } catch (e) {
        // Fallback if parsing fails
      }
    }
    return true; 
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
