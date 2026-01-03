import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/flights_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/seat.dart';
import '../../shared/widgets/seat_widget.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class SeatSelectionPage extends StatefulWidget {
  final int flightId;
  final List<dynamic> passengers;

  const SeatSelectionPage({super.key, required this.flightId, required this.passengers});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  late final ApiClient _apiClient;
  late final FlightsApi _flightsApi;
  List<Seat> _seats = [];
  final Set<String> _selectedSeatNumbers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _flightsApi = FlightsApi(_apiClient);
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() => _isLoading = true);

    try {
      final seatMap = await _flightsApi.getSeatMap(widget.flightId);
      setState(() {
        _seats = seatMap.seats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _toggleSeat(Seat seat) {
    if (!seat.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This seat is not available')),
      );
      return;
    }

    setState(() {
      if (_selectedSeatNumbers.contains(seat.seatNumber)) {
        _selectedSeatNumbers.remove(seat.seatNumber);
      } else {
        if (_selectedSeatNumbers.length >= widget.passengers.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select ${widget.passengers.length} seats'),
            ),
          );
          return;
        }
        _selectedSeatNumbers.add(seat.seatNumber);
      }
    });
  }

  void _continue() {
    if (_selectedSeatNumbers.length != widget.passengers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select ${widget.passengers.length} seats'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRouter.bookingReview,
      arguments: {
        'flightId': widget.flightId,
        'passengers': widget.passengers,
        'selectedSeats': _selectedSeatNumbers.toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seats'),
      ),
      body: _isLoading
          ? const LoadingView()
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected: ${_selectedSeatNumbers.length}/${widget.passengers.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: _selectedSeatNumbers.length == widget.passengers.length
                            ? _continue
                            : null,
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
                const SeatLegend(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildSeatGrid(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selectedSeatNumbers.length == widget.passengers.length
              ? _continue
              : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue to Review'),
        ),
      ),
    );
  }

  Widget _buildSeatGrid() {
    if (_seats.isEmpty) {
      return const Center(child: Text('No seats available'));
    }

    // Group seats by row
    final Map<String, List<Seat>> seatsByRow = {};
    for (final seat in _seats) {
      final row = seat.seatNumber.replaceAll(RegExp(r'[A-Z]'), '');
      seatsByRow.putIfAbsent(row, () => []).add(seat);
    }

    return Column(
      children: seatsByRow.entries.map((entry) {
        final row = entry.key;
        final seats = entry.value;
        seats.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                child: Text(row, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              ...seats.map((seat) {
                final isSelected = _selectedSeatNumbers.contains(seat.seatNumber);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SeatWidget(
                    seat: seat,
                    isSelected: isSelected,
                    onTap: () => _toggleSeat(seat),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
