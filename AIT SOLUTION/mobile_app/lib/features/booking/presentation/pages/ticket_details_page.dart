import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_event.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_state.dart';

class TicketDetailsPage extends StatefulWidget {
  final int bookingId;

  const TicketDetailsPage({super.key, required this.bookingId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<BookingBloc>()
        .add(GetTicketDetailsRequested(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ticket Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Принудительно обновляем список бронирований
              context.read<BookingBloc>().add(GetMyBookingsRequested());
              // Переходим на главную страницу
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            tooltip: 'На главную',
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
          } else if (state is TicketDetailsLoaded) {
            return _buildTicketDetails(state.ticketDetails);
          } else if (state is BookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading ticket details',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<BookingBloc>()
                          .add(GetTicketDetailsRequested(widget.bookingId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTicketDetails(Map<String, dynamic> ticketDetails) {
    final flight = ticketDetails['flight'] as Map<String, dynamic>?;
    final tickets = ticketDetails['tickets'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с номером бронирования
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticketDetails['booking_reference'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CHECKED IN',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Flight ${flight?['flight_number'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Информация о рейсе
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flight Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Маршрут
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AirportInfo(
                        code: flight?['departure_airport']?['code'] ?? 'DEP',
                        city: flight?['departure_airport']?['city'] ??
                            'Departure',
                        time: flight?['scheduled_departure'],
                        gate: flight?['gate_departure'],
                        label: 'DEPARTURE',
                      ),
                      const Icon(Icons.flight_takeoff,
                          color: Colors.grey, size: 24),
                      _AirportInfo(
                        code: flight?['arrival_airport']?['code'] ?? 'ARR',
                        city: flight?['arrival_airport']?['city'] ?? 'Arrival',
                        time: flight?['scheduled_arrival'],
                        gate: flight?['gate_arrival'],
                        label: 'ARRIVAL',
                        crossAxisAlignment: CrossAxisAlignment.end,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Дополнительная информация
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoItem(
                        label: 'AIRCRAFT',
                        value: flight?['airplane']?['model'] ?? 'N/A',
                      ),
                      _InfoItem(
                        label: 'TOTAL PRICE',
                        value:
                            '\$${ticketDetails['total_price']?.toStringAsFixed(0) ?? '0'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Билеты пассажиров
          const Text(
            'Passenger Tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),

          ...tickets
              .map<Widget>((ticket) => _TicketCard(ticket: ticket))
              .toList(),

          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Принудительно обновляем список бронирований перед переходом
                    context.read<BookingBloc>().add(GetMyBookingsRequested());
                    // Используем pushReplacement для замены текущей страницы
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Назад к бронированиям'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A2E),
                    side: const BorderSide(color: Color(0xFF1A1A2E)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Принудительно обновляем список бронирований
                    context.read<BookingBloc>().add(GetMyBookingsRequested());
                    // Переходим на главную страницу
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('На главную'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirportInfo extends StatelessWidget {
  final String code;
  final String city;
  final String? time;
  final String? gate;
  final String label;
  final CrossAxisAlignment crossAxisAlignment;

  const _AirportInfo({
    required this.code,
    required this.city,
    this.time,
    this.gate,
    required this.label,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          code,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          city,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        if (time != null) ...[
          const SizedBox(height: 8),
          Text(
            _formatTime(time!),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
        if (gate != null) ...[
          const SizedBox(height: 4),
          Text(
            'Gate $gate',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final seat = ticket['seat'] as Map<String, dynamic>?;
    final seatClass =
        seat != null ? seat['class']?.toString().toUpperCase() : '';
    final seatClassDisplay =
        seatClass == 'BUSINESS' ? 'EXTRA ROOM FOR LEGS' : seatClass;
    final seatDisplay = seat != null
        ? '${seat['row']}${seat['letter']} ($seatClassDisplay)'
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Первая строка: QR Code и основная информация
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: ticket['qr_code'] ?? 'NO-QR',
                    version: QrVersions.auto,
                    size: 80,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                // Информация о билете
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['passenger_name'] ?? 'Passenger',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket: ${ticket['ticket_number'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.airline_seat_recline_normal,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seat $seatDisplay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Дополнительная информация о пассажире
            if ((ticket['passenger_phone'] != null &&
                    ticket['passenger_phone'].toString().trim().isNotEmpty) ||
                (ticket['passenger_passport_number'] != null &&
                    ticket['passenger_passport_number']
                        .toString()
                        .trim()
                        .isNotEmpty) ||
                (ticket['passenger_nationality'] != null &&
                    ticket['passenger_nationality']
                        .toString()
                        .trim()
                        .isNotEmpty)) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Passenger Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              if (ticket['passenger_phone'] != null &&
                  ticket['passenger_phone'].toString().trim().isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ticket['passenger_phone'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (ticket['passenger_passport_number'] != null &&
                  ticket['passenger_passport_number']
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Passport ID: ${ticket['passenger_passport_number'].toString()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (ticket['passenger_nationality'] != null &&
                  ticket['passenger_nationality']
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nationality: ${ticket['passenger_nationality'].toString()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
