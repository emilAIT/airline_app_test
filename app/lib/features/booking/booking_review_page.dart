import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/bookings_api.dart';
import '../../shared/api/flights_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/flight.dart';
import '../../shared/models/seat.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';
import '../../app/router.dart';

class BookingReviewPage extends StatefulWidget {
  final int flightId;
  final List<dynamic> passengers;
  final List<dynamic> selectedSeats;

  const BookingReviewPage({
    super.key,
    required this.flightId,
    required this.passengers,
    required this.selectedSeats,
  });

  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage> {
  late final ApiClient _apiClient;
  late final FlightsApi _flightsApi;
  late final BookingsApi _bookingsApi;
  
  Flight? _flight;
  List<Seat>? _seats;
  bool _isLoading = true;
  bool _isCreatingBooking = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _flightsApi = FlightsApi(_apiClient);
    _bookingsApi = BookingsApi(_apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final flight = await _flightsApi.getFlight(widget.flightId);
      final seatMap = await _flightsApi.getSeatMap(widget.flightId);
      
      final selectedSeats = seatMap.seats
          .where((seat) => widget.selectedSeats.contains(seat.seatNumber))
          .toList();

      setState(() {
        _flight = flight;
        _seats = selectedSeats;
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

  Future<void> _createBooking() async {
    setState(() => _isCreatingBooking = true);

    try {
      // map passengers and seats to the structure expected by the backend
      final List<Map<String, dynamic>> payloadPassengers = [];
      for (int i = 0; i < widget.passengers.length; i++) {
        final passenger = widget.passengers[i];
        String? seatNumber;
        if (i < widget.selectedSeats.length) {
          seatNumber = widget.selectedSeats[i] as String?;
        }
        
        payloadPassengers.add({
          'passenger_name': passenger['full_name'],
          'passport_number': passenger['passport_number'],
          'seat_number': seatNumber,
        });
      }

      final booking = await _bookingsApi.createBooking({
        'flight_id': widget.flightId,
        'passengers': payloadPassengers,
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.payment,
          arguments: booking.pnr, // Pass PNR instead of ID
        );
      }
    } catch (e) {
      setState(() => _isCreatingBooking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  double _calculateTotal() {
    if (_flight == null || _seats == null) return 0;
    return _seats!.fold(0.0, (sum, seat) => sum + seat.price);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Booking')),
        body: const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flight Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_flight != null) ...[
                      _buildInfoRow('Flight', _flight!.flightNumber),
                      _buildInfoRow('From', _flight!.origin?.city ?? 'N/A'),
                      _buildInfoRow('To', _flight!.destination?.city ?? 'N/A'),
                      _buildInfoRow('Departure', Formatters.formatDateTime(_flight!.departureTime)),
                      _buildInfoRow('Arrival', Formatters.formatDateTime(_flight!.arrivalTime)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passengers & Seats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ...widget.passengers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final passenger = entry.value;
                      final seat = _seats != null && index < _seats!.length
                          ? _seats![index]
                          : null;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passenger['full_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Seat: ${seat?.seatNumber ?? 'N/A'} • ${seat?.category.name ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (seat != null)
                              Text(
                                '\$${seat.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '\$${_calculateTotal().toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Proceed to Payment',
              onPressed: _createBooking,
              isLoading: _isCreatingBooking,
              icon: Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
