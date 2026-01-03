import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/presentation/cubits/booking_cubit.dart';
import 'package:airline_app/presentation/cubits/auth_cubit.dart';
import 'package:airline_app/presentation/screens/flights/booking_confirmation_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int flightId;
  final Map<String, dynamic> seatTemplate;

  const SeatSelectionScreen({
    super.key,
    required this.flightId,
    required this.seatTemplate,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _selectedSeat;

  void _onConfirm() {
    if (_selectedSeat != null) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated && authState.profile != null) {
        // Backend expects passenger_profile_id and seat_number
        context.read<BookingCubit>().initiateBooking(
          widget.flightId,
          [
            {
              'passenger_profile_id': authState.profile!.id,
              'seat_number': _selectedSeat,
            }
          ],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Seat')),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingInitiated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingConfirmationScreen(booking: state.booking),
              ),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildLegend(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: _buildSeatMap(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton(
                  onPressed: _selectedSeat == null || state is BookingLoading ? null : _onConfirm,
                  child: state is BookingLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_selectedSeat == null ? 'SELECT A SEAT' : 'CONFIRM SEAT $_selectedSeat'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: Colors.grey[300]!, label: 'Available'),
          _LegendItem(color: Theme.of(context).colorScheme.primary, label: 'Selected'),
          _LegendItem(color: Colors.red, label: 'Booked'),
        ],
      ),
    );
  }

  Widget _buildSeatMap() {
    final rows = widget.seatTemplate['rows'] as List;
    final config = widget.seatTemplate['config'] as String; // e.g., "ABC_DEF"
    
    return Column(
      children: rows.map((row) {
        final rowNum = row['row'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: config.split('').map((char) {
                if (char == '_') return const SizedBox(width: 24);
                
                final seatId = '$rowNum$char';
                final isBooked = (row['seats'] as Map)[char] == false;
                final isSelected = _selectedSeat == seatId;

                return GestureDetector(
                  onTap: isBooked ? null : () => setState(() => _selectedSeat = seatId),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.red
                          : (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        char,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.white : (isBooked ? Colors.white : Colors.black54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
