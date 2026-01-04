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

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  @override
  void initState() {
    super.initState();
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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Payment History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              navigateToHome(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => navigateToHome(context),
            tooltip: 'Home',
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            );
          } else if (state is BookingsLoaded) {
            // Фильтруем только оплаченные билеты (paid или checked_in)
            // Это история всех оплаченных билетов пользователя
            final historyBookings = state.bookings.where((booking) {
              return booking.status == 'paid' || booking.status == 'checked_in';
            }).toList();

            if (historyBookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.white54),
                    const SizedBox(height: 16),
                    const Text(
                      'No paid tickets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your paid tickets will appear here',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<BookingBloc>().add(GetMyBookingsRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: historyBookings.length,
                itemBuilder: (context, index) => _HistoryBookingCard(
                  booking: historyBookings[index],
                  onViewTicketDetails: (booking) {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => TicketDetailsPage(bookingId: booking.id),
                      ),
                    )
                        .then((_) {
                      if (mounted) {
                        _loadBookings();
                      }
                    });
                  },
                ),
              ),
            );
          } else if (state is BookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE94560)),
          );
        },
      ),
    );
  }
}

class _HistoryBookingCard extends StatelessWidget {
  final Booking booking;
  final Function(Booking) onViewTicketDetails;

  const _HistoryBookingCard({
    required this.booking,
    required this.onViewTicketDetails,
  });

  @override
  Widget build(BuildContext context) {
    final flight = booking.flight;
    final flightId = flight?.id ?? booking.flightId;
    final flightDate = flight != null
        ? DateFormat('dd MMM yyyy').format(flight.scheduledDeparture)
        : '--';
    final price = '\$${booking.totalPrice.toStringAsFixed(2)}';

    return InkWell(
      onTap: () => onViewTicketDetails(booking),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        'Flight ID: $flightId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.bookingReference,
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status == 'checked_in' 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status == 'checked_in' ? 'CHECKED IN' : 'PAID',
                      style: TextStyle(
                        color: booking.status == 'checked_in' ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                    label: 'DATE',
                    value: flightDate,
                  ),
                  _InfoItem(
                    label: 'PRICE',
                    value: price,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.white60),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to view full details',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

