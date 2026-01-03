import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/flights_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/seat.dart';
import '../../shared/widgets/seat_widget.dart';

import '../../shared/widgets/loading_view.dart';
import '../../shared/utils/constants.dart';

class SeatMapPage extends StatefulWidget {
  final int flightId;

  const SeatMapPage({super.key, required this.flightId});

  @override
  State<SeatMapPage> createState() => _SeatMapPageState();
}

class _SeatMapPageState extends State<SeatMapPage> {
  late final ApiClient _apiClient;
  late final FlightsApi _flightsApi;
  List<Seat> _seats = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Map'),
      ),
      body: _isLoading
          ? const LoadingView()
          : Column(
              children: [
                const SeatLegend(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildSeatGrid(),
                  ),
                ),
              ],
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SeatWidget(
                    seat: seat,
                    isSelected: false,
                    onTap: null, // View only
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
