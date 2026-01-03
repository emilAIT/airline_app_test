import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class StaffBookingsScreen extends StatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  State<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends State<StaffBookingsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  final _pnrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _api.getStaffBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _searchByPnr() async {
    if (_pnrController.text.trim().isEmpty) {
      _loadBookings();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bookings = await _api.getStaffBookings(
        pnr: _pnrController.text.trim(),
      );
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching bookings: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: EldiyarTheme.primaryBlue,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Manage Bookings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: EldiyarTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pnrController,
                          style: const TextStyle(
                            color: EldiyarTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Search by PNR',
                            prefixIcon: Icon(
                              Icons.search,
                              color: EldiyarTheme.primaryBlue,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchByPnr(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlowButton(
                        label: 'Search',
                        icon: Icons.search,
                        onPressed: _searchByPnr,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bookings List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : _bookings.isEmpty
                    ? const Center(
                        child: Text(
                          'No bookings found',
                          style: TextStyle(color: EldiyarTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final flight = booking['flight'];
                            final departureTime = DateTime.parse(
                              flight['departure_time'],
                            );

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'PNR: ${booking['pnr']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: EldiyarTheme.primaryBlue,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            booking['status'],
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              booking['status'],
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          booking['status'],
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              booking['status'],
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    flight['flight_number'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${flight['origin']['code']} → ${flight['destination']['code']}',
                                    style: const TextStyle(
                                      color: EldiyarTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy HH:mm',
                                    ).format(departureTime),
                                    style: const TextStyle(
                                      color: EldiyarTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(booking['tickets'] as List).length} ticket(s)',
                                    style: const TextStyle(
                                      color: EldiyarTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CREATED':
        return EldiyarTheme.primaryBlue;
      case 'CONFIRMED':
        return EldiyarTheme.successGreen;
      case 'CANCELLED':
        return EldiyarTheme.errorRed;
      default:
        return EldiyarTheme.textSecondary;
    }
  }
}
