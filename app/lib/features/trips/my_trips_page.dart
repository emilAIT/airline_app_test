import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/bookings_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/booking_card.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  late final ApiClient _apiClient;
  late final BookingsApi _bookingsApi;
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _bookingsApi = BookingsApi(_apiClient);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await _bookingsApi.getMyBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadBookings)
              : _bookings.isEmpty
                  ? const EmptyView(
                      message: 'No bookings found\nBook your first flight to see it here',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          return BookingCard(
                            booking: booking,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.tripDetails,
                                arguments: booking.id,
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
