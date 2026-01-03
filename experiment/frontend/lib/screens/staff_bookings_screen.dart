import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../services/staff_service.dart';
import '../models/booking.dart';
import '../core/theme/app_theme.dart';
import 'staff_main_screen.dart';

class StaffBookingsScreen extends ConsumerStatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  ConsumerState<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends ConsumerState<StaffBookingsScreen> {
  final _pnrController = TextEditingController();
  List<Booking> _allBookings = [];
  List<Booking> _filteredBookings = [];
  Booking? _selectedBooking;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  String _searchMode = 'all'; // 'all' or 'pnr'

  @override
  void initState() {
    super.initState();
    _loadAllBookings();
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searchMode = 'all';
      _selectedBooking = null;
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final bookings = await staffService.getAllBookings();
      setState(() {
        _allBookings = bookings;
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

  Future<void> _searchByPnr() async {
    final pnr = _pnrController.text.trim();
    if (pnr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PNR code')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _selectedBooking = null;
      _searchMode = 'pnr';
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final booking = await staffService.getBookingByPnr(pnr.toUpperCase());
      setState(() {
        _selectedBooking = booking;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _deleteBooking(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to permanently delete this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final staffService = ref.read(staffServiceProvider);
      await staffService.deleteBooking(bookingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh data
        if (_searchMode == 'pnr' && _selectedBooking?.id == bookingId) {
          _searchByPnr(); // Refresh PNR search
        } else {
          _loadAllBookings(); // Refresh all bookings
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting booking: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final staffService = ref.read(staffServiceProvider);
      await staffService.cancelBooking(bookingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh data
        if (_searchMode == 'pnr' && _selectedBooking?.id == bookingId) {
          _searchByPnr(); // Refresh PNR search
        } else {
          _loadAllBookings(); // Refresh all bookings
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }

  Future<void> _reassignSeat(Booking booking, int ticketId, String currentSeat) async {
    final newSeatController = TextEditingController(text: currentSeat);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Seat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current seat: $currentSeat'),
            const SizedBox(height: 16),
            TextField(
              controller: newSeatController,
              decoration: const InputDecoration(
                labelText: 'New Seat Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., 12A',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newSeat = newSeatController.text.trim().toUpperCase();
    if (newSeat.isEmpty || newSeat == currentSeat) {
      return;
    }

    try {
      final staffService = ref.read(staffServiceProvider);
      await staffService.reassignSeat(
        ticketId: ticketId,
        newSeatNumber: newSeat,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seat reassigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh data
        if (_searchMode == 'pnr' && _selectedBooking?.id == booking.id) {
          _searchByPnr();
        } else {
          _loadAllBookings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reassigning seat: $e')),
        );
      }
    }
    
    newSeatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
              ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw, color: Colors.white),
            onPressed: _loadAllBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search/Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pnrController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Search by PNR',
                          hintText: 'Enter PNR code',
                          prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textSecondary),
                          suffixIcon: _pnrController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    _pnrController.clear();
                                    setState(() {
                                      _selectedBooking = null;
                                      _searchMode = 'all';
                                    });
                                    _loadAllBookings();
                                  },
                                )
                              : null,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _searchByPnr(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchByPnr,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.arrowRight, size: 16),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _searchMode == 'all' ? null : () {
                        setState(() {
                          _searchMode = 'all';
                          _selectedBooking = null;
                          _pnrController.clear();
                        });
                        _loadAllBookings();
                      },
                      icon: const Icon(LucideIcons.list, size: 16),
                      label: const Text('Show All Bookings'),
                      style: TextButton.styleFrom(
                        foregroundColor: _searchMode == 'all' ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _searchMode == 'pnr' ? _searchByPnr : _loadAllBookings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _searchMode == 'pnr'
                        ? _selectedBooking == null
                            ? const Center(child: Text('No booking found', style: TextStyle(color: AppTheme.textSecondary)))
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: _buildBookingCard(_selectedBooking!),
                              )
                        : _filteredBookings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.ticket, size: 64, color: Colors.grey.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No bookings found',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadAllBookings,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredBookings.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    return _buildBookingCard(_filteredBookings[index]);
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final flight = booking.flight;
    
    return Card(
      color: AppTheme.surfaceColor,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: PNR and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PNR Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.pnr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Flight Info
            if (flight != null) ...[
              Row(
                children: [
                  const Icon(LucideIcons.plane, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flight ${flight.flightNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Text(
                      '${flight.departureAirportCode} → ${flight.arrivalAirportCode}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(flight.departureTime),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Passengers and Seats
            const Text(
              'Passengers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...booking.tickets.map((ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.user, size: 16, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ticket.passengerName,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          'Seat ${ticket.seatNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!booking.isCancelled)
                        IconButton(
                          icon: const Icon(LucideIcons.edit2, size: 16, color: AppTheme.primaryColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _reassignSeat(booking, ticket.id, ticket.seatNumber),
                          tooltip: 'Reassign seat',
                        ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Booking Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Created',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(booking.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            
            if (!booking.isCancelled) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking.id),
                      icon: const Icon(LucideIcons.xCircle, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteBooking(booking.id),
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppTheme.successColor;
      case 'PENDING':
        return AppTheme.warningColor;
      case 'CANCELLED':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}
