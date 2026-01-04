import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_event.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_state.dart';
import 'package:ait_airlines/features/booking/domain/entities/booking.dart';
import 'package:ait_airlines/features/booking/presentation/pages/ticket_details_page.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные при каждом возврате на страницу
    // Это гарантирует, что после check-in список будет обновлен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  void _loadBookings() {
    context.read<BookingBloc>().add(GetMyBookingsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => navigateToHome(context),
            icon: const Icon(Icons.home),
            tooltip: 'На главную',
          ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Обновляем список бронирований после отмены
            context.read<BookingBloc>().add(GetMyBookingsRequested());
          } else if (state is CheckInSuccess) {
            // Обновляем список бронирований после успешного check-in
            context.read<BookingBloc>().add(GetMyBookingsRequested());
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
          } else if (state is BookingsLoaded) {
            // Фильтруем только активные бронирования (pending, paid, checked_in)
            // Исключаем оплаченные билеты, которые должны быть в истории
            // Но показываем все активные, включая оплаченные, которые еще не завершены
            final now = DateTime.now();
            final activeBookings = state.bookings.where((booking) {
              // Показываем pending (неоплаченные)
              if (booking.status == 'pending') return true;
              // Показываем paid и checked_in только если рейс еще не вылетел
              if (booking.status == 'paid' || booking.status == 'checked_in') {
                if (booking.flight == null) return true;
                return booking.flight!.scheduledDeparture.isAfter(now);
              }
              // Исключаем cancelled и refunded
              return false;
            }).toList();
            
            if (activeBookings.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BookingBloc>().add(GetMyBookingsRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeBookings.length,
                itemBuilder: (context, index) => _BookingCard(
                  booking: activeBookings[index],
                  onCancelBooking: _showCancelDialog,
                  onViewTicketDetails: _viewTicketDetails,
                ),
              ),
            );
          } else if (state is BookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          // Показываем индикатор загрузки по умолчанию
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
        },
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Отменить бронирование'),
          content: Text(
              'Вы уверены, что хотите отменить бронирование ${booking.bookingReference}?\n\n'
              'Отмена возможна только за 24+ часов до вылета.\n'
              'Сумма к возврату: \$${booking.totalPrice.toStringAsFixed(0)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context
                    .read<BookingBloc>()
                    .add(CancelBookingRequested(booking.id));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Подтвердить отмену',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _viewTicketDetails(Booking booking) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(bookingId: booking.id),
      ),
    )
        .then((_) {
      // Обновляем список бронирований при возврате
      if (mounted) {
        _loadBookings();
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.airplane_ticket_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No bookings found',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your future trips will appear here',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Function(Booking) onCancelBooking;
  final Function(Booking) onViewTicketDetails;

  const _BookingCard({
    required this.booking,
    required this.onCancelBooking,
    required this.onViewTicketDetails,
  });

  @override
  Widget build(BuildContext context) {
    final flight = booking.flight;
    final isPending = booking.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        onTap: isPending
            ? () => context.push('/payments/checkout', extra: booking)
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.bookingReference,
                    style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AirportDisplay(
                    code: flight?.departureAirport.iataCode ?? 'DEP',
                    city: flight?.departureAirport.city ?? 'Departure',
                  ),
                  const Icon(Icons.flight_takeoff,
                      color: Colors.grey, size: 20),
                  _AirportDisplay(
                    code: flight?.arrivalAirport.iataCode ?? 'ARR',
                    city: flight?.arrivalAirport.city ?? 'Arrival',
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                      label: 'DATE',
                      value: flight != null
                          ? DateFormat('dd MMM yyyy')
                              .format(flight.scheduledDeparture)
                          : '--'),
                  _InfoItem(
                      label: 'PRICE',
                      value: '\$${booking.totalPrice.toStringAsFixed(0)}'),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 16, color: Color(0xFFE94560)),
                      SizedBox(width: 8),
                      Text('PAY NOW',
                          style: TextStyle(
                              color: Color(0xFFE94560),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ] else if (booking.status == 'paid') ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    // Check-in доступен только в диапазоне от 24 часов до рейса до 1 часа до рейса
                    final now = DateTime.now();

                    if (flight == null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Flight information not available',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    // Check-in доступен только в диапазоне от 24 часов до рейса до 1 часа до рейса
                    DateTime departureTime = flight.scheduledDeparture;
                    final timeUntilDeparture = departureTime.difference(now);
                    
                    // Check-in доступен если:
                    // 1. Рейс еще не вылетел
                    // 2. До рейса осталось не более 24 часов
                    // 3. До рейса осталось не менее 1 часа
                    bool canCheckIn = departureTime.isAfter(now) &&
                        timeUntilDeparture <= const Duration(hours: 24) &&
                        timeUntilDeparture >= const Duration(hours: 1);

                    if (canCheckIn) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/bookings/${booking.id}/checkin'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Check-In Available'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    } else {
                      // Определяем причину недоступности и показываем соответствующее сообщение
                      String message;
                      IconData icon;

                      if (!departureTime.isAfter(now)) {
                        // Рейс уже вылетел
                        message = 'Flight has departed';
                        icon = Icons.flight_takeoff;
                      } else if (timeUntilDeparture > const Duration(hours: 24)) {
                        // Слишком рано - check-in откроется за 24 часа до рейса
                        final hoursUntilCheckIn = (timeUntilDeparture.inHours - 24);
                        message = 'Check-in opens 24 hours before flight (in $hoursUntilCheckIn hours)';
                        icon = Icons.schedule;
                      } else if (timeUntilDeparture < const Duration(hours: 1)) {
                        // Слишком поздно - check-in закрылся за 1 час до рейса
                        message = 'Check-in closed (closed 1 hour before flight)';
                        icon = Icons.lock_clock;
                      } else {
                        // Другая причина
                        message = 'Check-in not available';
                        icon = Icons.error_outline;
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(message,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ] else if (booking.status == 'checked_in') ...[
                const SizedBox(height: 16),
                // Кнопка просмотра деталей билета после check-in
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onViewTicketDetails(booking),
                    icon: const Icon(Icons.airplane_ticket),
                    label: const Text('View Ticket Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              // Кнопка отмены бронирования (доступна для paid статуса, если до рейса >24ч)
              if (booking.status == 'paid') ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    if (flight == null) {
                      return const SizedBox.shrink();
                    }
                    final now = DateTime.now();
                    DateTime departureTime = flight.scheduledDeparture;
                    final canCancel = departureTime.isAfter(now) &&
                        departureTime.difference(now).inHours > 24;

                    if (canCancel) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onCancelBooking(booking),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('Cancellation available >24h before departure',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'checked_in':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

class _AirportDisplay extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment crossAxisAlignment;
  const _AirportDisplay(
      {required this.code,
      required this.city,
      this.crossAxisAlignment = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(code,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        Text(city, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
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
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }
}
