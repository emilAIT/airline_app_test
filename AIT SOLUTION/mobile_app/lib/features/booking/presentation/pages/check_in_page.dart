import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_event.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_state.dart';

class CheckInPage extends StatefulWidget {
  final int? bookingId;
  const CheckInPage({super.key, this.bookingId});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final _bookingIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingIdController.text = widget.bookingId.toString();
      // Auto-submit if booking ID is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BookingBloc>().add(CheckInRequested(widget.bookingId!));
      });
    }
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_bookingIdController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите bookingId')));
      return;
    }
    final id = int.tryParse(_bookingIdController.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Некорректный bookingId')));
      return;
    }
    context.read<BookingBloc>().add(CheckInRequested(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In (открывается за 24ч, закрывается за 1ч)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is CheckInSuccess) {
            print('DEBUG CheckInSuccess: ${state.data}');
            // Показываем сообщение об успехе
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check-in успешно завершен!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Принудительно обновляем список бронирований и возвращаемся через 2 секунды
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                // Обновляем список бронирований перед возвратом
                context.read<BookingBloc>().add(GetMyBookingsRequested());
                // Возвращаемся к списку бронирований
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/bookings');
                }
              }
            });
          }
        },
        builder: (context, state) {
          final loading = state is BookingLoading;
          if (state is CheckInSuccess) {
            return _buildSuccessView(state.data);
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _bookingIdController,
                  decoration: const InputDecoration(
                    labelText: 'Booking ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: widget.bookingId == null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Проверить'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessView(Map<String, dynamic> data) {
    final flight = data['flight'] as Map<String, dynamic>?;
    final tickets = data['tickets'] as List<dynamic>? ?? [];
    final gateDep = data['gate_departure'] as String? ?? '';
    final gateArr = data['gate_arrival'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Check-in успешно завершен!',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Flight Info Card
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flight: ${flight?['flight_number'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Departure Gate',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(gateDep,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Arrival Gate',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(gateArr,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Your Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Tickets List
          ...tickets.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value as Map<String, dynamic>;
            final seat = t['seat'] as Map<String, dynamic>?;
            final seatRow = seat?['row']?.toString() ?? '';
            final seatLetter = seat?['letter']?.toString() ?? '';
            final seatClass = t['class']?.toString().toUpperCase() ?? '';
            final qr = t['qr']?.toString() ?? '';
            final firstName = t['passenger_first_name']?.toString() ?? '';
            final lastName = t['passenger_last_name']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ticket ${index + 1}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: seatClass == 'BUSINESS'
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            seatClass == 'BUSINESS'
                                ? 'EXTRA ROOM FOR LEGS'
                                : seatClass,
                            style: TextStyle(
                              color: seatClass == 'BUSINESS'
                                  ? Colors.blue.shade900
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (firstName.isNotEmpty || lastName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$firstName $lastName',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seat',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              Text(
                                '$seatRow$seatLetter',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('QR Code',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              SelectableText(
                                qr,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),
          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Принудительно обновляем список бронирований перед переходом
                    context.read<BookingBloc>().add(GetMyBookingsRequested());
                    // Ждем немного для обновления данных, затем переходим
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        // Используем pushReplacement для замены текущей страницы
                        context.pushReplacement('/bookings');
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Назад к бронированиям'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
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
                    // Используем go_router для перехода на главную
                    navigateToHome(context);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('На главную'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
