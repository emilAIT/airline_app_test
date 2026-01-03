import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:airline_app/domain/entities/booking.dart';
import 'package:airline_app/presentation/cubits/auth_cubit.dart';
import 'package:intl/intl.dart';

class CheckinScreen extends StatelessWidget {
  final Booking booking;
  const CheckinScreen({super.key, required this.booking});

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '---';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = booking.tickets.first;
    final authState = context.watch<AuthCubit>().state;
    String passengerName = 'PASSENGER';
    
    if (authState is Authenticated && authState.profile != null) {
      passengerName = authState.profile!.fullName;
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Boarding Pass')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top part: Flight Info
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF673AB7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Passenger Name
                        Text(
                          passengerName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(booking.flight?.scheduledDeparture),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        
                        // Airport codes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _TicketAirportRow(
                              code: booking.flight?.origin.code ?? '---',
                              city: booking.flight?.origin.city ?? 'Origin',
                            ),
                            const Icon(Icons.airplanemode_active, color: Colors.white, size: 30),
                            _TicketAirportRow(
                              code: booking.flight?.destination.code ?? '---',
                              city: booking.flight?.destination.city ?? 'Dest',
                              align: CrossAxisAlignment.end,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Departure and Arrival times
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DEPARTURE', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(
                                  _formatTime(booking.flight?.scheduledDeparture),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('ARRIVAL', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(
                                  _formatTime(booking.flight?.scheduledArrival),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Flight details row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _TicketInfoCol(label: 'FLIGHT', value: booking.flight?.flightNumber ?? '---'),
                            _TicketInfoCol(label: 'GATE', value: booking.flight?.gate ?? 'TBA'),
                            _TicketInfoCol(label: 'SEAT', value: ticket.seatNumber),
                            _TicketInfoCol(label: 'TERMINAL', value: booking.flight?.terminal ?? 'T1'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Perforated line effect
                  Row(
                    children: List.generate(
                      15,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 2,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),

                  // Boarding info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItem(label: 'PNR', value: booking.pnr),
                        _DetailItem(label: 'BOOKING ID', value: '#${booking.id}'),
                        _DetailItem(label: 'STATUS', value: booking.status.name.toUpperCase()),
                      ],
                    ),
                  ),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    child: Column(
                      children: [
                        QrImageView(
                          data: 'PNR:${booking.pnr}|TICKET:${ticket.ticketNumber}|SEAT:${ticket.seatNumber}|FLIGHT:${booking.flight?.flightNumber}',
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF673AB7)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF673AB7)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scan at the gate for boarding',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please arrive at the gate 30 minutes before departure',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketAirportRow extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment align;

  const _TicketAirportRow({required this.code, required this.city, this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(code, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(city, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}

class _TicketInfoCol extends StatelessWidget {
  final String label;
  final String value;

  const _TicketInfoCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
