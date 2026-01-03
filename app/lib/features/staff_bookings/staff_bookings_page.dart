import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/widgets/booking_card.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class StaffBookingsPage extends StatefulWidget {
  const StaffBookingsPage({super.key});

  @override
  State<StaffBookingsPage> createState() => _StaffBookingsPageState();
}

class _StaffBookingsPageState extends State<StaffBookingsPage> {
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = false;
  String? _error;
  final _pnrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _staffApi = StaffApi(_apiClient);
    _loadBookings();
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await _staffApi.getAllBookings();
      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByPNR() async {
    final pnr = _pnrController.text.trim().toUpperCase();
    
    if (pnr.isEmpty) {
      setState(() => _filteredBookings = _bookings);
      return;
    }

    // If PNR is exactly 6 characters, try searching backend
    if (pnr.length == 6) {
      setState(() => _isLoading = true);
      try {
        final booking = await _staffApi.searchBooking(pnr);
        setState(() {
          _filteredBookings = [booking];
          _isLoading = false;
        });
      } catch (e) {
        // If not found in backend, filter locally
        setState(() {
          _filteredBookings = _bookings.where((b) => b.pnr.contains(pnr)).toList();
          _isLoading = false;
        });
      }
    } else {
      // Filter locally for partial matches
      setState(() {
        _filteredBookings = _bookings.where((b) => b.pnr.contains(pnr)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _pnrController,
              decoration: InputDecoration(
                labelText: 'Search by PNR',
                hintText: 'Enter 6-character PNR code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _pnrController.clear();
                    setState(() => _filteredBookings = _bookings);
                  },
                ),
              ),
              onSubmitted: (_) => _searchByPNR(),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredBookings.length} booking(s)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: _searchByPNR,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadBookings)
                    : _filteredBookings.isEmpty
                        ? const EmptyView(message: 'No bookings found')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _filteredBookings[index];
                              return BookingCard(
                                booking: booking,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRouter.staffBookingSearch,
                                    arguments: booking.pnr,
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
