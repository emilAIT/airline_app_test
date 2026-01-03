import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/presentation/cubits/booking_cubit.dart';
import 'package:airline_app/domain/entities/booking.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;
  const BookingConfirmationScreen({super.key, required this.booking});

  void _onPay(BuildContext context) {
    context.read<BookingCubit>().confirmBooking(
      booking.id,
      {'payment_method': 'card', 'card_last4': '4242'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingConfirmed) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Success!'),
                content: const Text('Your booking has been confirmed. You can now view it in "My Trips".'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                const Text(
                  'Seat Reserved',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'PNR: ${booking.pnr}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Seat Number', value: booking.tickets.first.seatNumber),
                        const Divider(),
                        const _InfoRow(label: 'Total Amount', value: '\$250.00'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Complete payment to finalize your booking.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state is BookingLoading ? null : () => _onPay(context),
                  child: state is BookingLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PAY NOW'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
