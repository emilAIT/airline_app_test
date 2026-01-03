import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/flight_service.dart';
import '../models/flight.dart';
import '../models/aviation.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'flight_details_screen.dart';
import 'passenger_main_screen.dart';

class FlightSearchScreen extends ConsumerStatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  ConsumerState<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends ConsumerState<FlightSearchScreen> {
  // Flight Type
  int _selectedFlightTypeIndex = 1; // 0: Round Trip, 1: One Way
  final List<String> _flightTypes = ['Round Trip', 'One Way'];

  // Airports
  Airport? _selectedDepartureAirport;
  Airport? _selectedArrivalAirport;
  
  // Dates
  DateTime? _departureDate;
  DateTime? _returnDate;

  // Passengers
  int _adults = 1;
  int _children = 0;
  bool _isPassengerExpanded = false;

  // Search State
  bool _isLoading = false;
  String? _error;
  List<Flight> _flights = [];
  List<Airport> _airports = [];

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    try {
      final flightService = ref.read(flightServiceProvider);
      final airports = await flightService.getAirports();
      if (mounted) {
        setState(() {
          _airports = airports;
        });
      }
    } catch (e) {
      print('Error loading airports: $e');
    }
  }

  Future<void> _showAirportPicker(bool isDeparture) async {
    List<Airport> filtered = _airports;
    TextEditingController searchCtrl = TextEditingController();

    final Airport? result = await showModalBottomSheet<Airport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B), // Dark background for modal
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Text(
                      isDeparture ? 'Select Departure' : 'Select Arrival',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search city, code or airport',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A), // Darker input bg
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      filtered = _airports.where((a) =>
                        a.code.toLowerCase().contains(val.toLowerCase()) ||
                        a.city.toLowerCase().contains(val.toLowerCase()) ||
                        a.name.toLowerCase().contains(val.toLowerCase())
                      ).toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[800]),
                  itemBuilder: (ctx, index) {
                    final airport = filtered[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          airport.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      title: Text(
                        airport.city,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        '${airport.name}, ${airport.country}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () => Navigator.pop(context, airport),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          if (isDeparture) {
            _selectedDepartureAirport = result;
          } else {
            _selectedArrivalAirport = result;
          }
        });
      }
    }
    searchCtrl.dispose();
  }

  Future<void> _selectDate(bool isDeparture) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isDeparture ? now : (_departureDate ?? now);
    final DateTime initialDate = isDeparture 
        ? (_departureDate ?? now) 
        : (_returnDate ?? _departureDate?.add(const Duration(days: 1)) ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E293B),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = null;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _searchFlights() async {
    if (_selectedDepartureAirport == null || _selectedArrivalAirport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure and arrival airports')),
      );
      return;
    }
    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a departure date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _flights = [];
    });

    try {
      final flightService = ref.read(flightServiceProvider);
      final flights = await flightService.searchFlights(
        origin: _selectedDepartureAirport!.code,
        destination: _selectedArrivalAirport!.code,
        date: _departureDate!,
      );

      // Filter out flights that have already departed (additional client-side check)
      final now = DateTime.now();
      final availableFlights = flights.where((flight) {
        return flight.departureTime.isAfter(now);
      }).toList();

      setState(() {
        _flights = availableFlights;
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
    // Main Dark theme background
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 

      appBar: AppBar(
        title: const Text('Search Flights'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
              ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
      ), 
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchCard(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else if (_flights.isNotEmpty)
              _buildFlightResults()
            else if (_flights.isEmpty && !_isLoading && _selectedDepartureAirport != null)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No flights found for this criteria.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Book a flight" text removed as requested
            
            // Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Darker bg for segmented control
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(_flightTypes.length, (index) {
                  final isSelected = _selectedFlightTypeIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFlightTypeIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent, // Primary when selected
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _flightTypes[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),

            // Airports - Stylized for Dark Mode (White Text)
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    label: 'From',
                    value: _selectedDepartureAirport?.code ?? 'Select',
                    subValue: _selectedDepartureAirport?.city ?? 'Departure',
                    icon: Icons.flight_takeoff_rounded,
                    onTap: () => _showAirportPicker(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputCard(
                    label: 'To',
                    value: _selectedArrivalAirport?.code ?? 'Select',
                    subValue: _selectedArrivalAirport?.city ?? 'Arrival',
                    icon: Icons.flight_land_rounded,
                    onTap: () => _showAirportPicker(false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    label: 'Departure',
                    value: _departureDate != null 
                        ? DateFormat('dd MMM').format(_departureDate!) 
                        : 'Select Date',
                    subValue: _departureDate != null 
                        ? DateFormat('EEEE').format(_departureDate!) 
                        : 'Tap to select',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _selectDate(true),
                  ),
                ),
                if (_selectedFlightTypeIndex == 0) ...[ // Round Trip
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputCard(
                      label: 'Return',
                      value: _returnDate != null 
                          ? DateFormat('dd MMM').format(_returnDate!) 
                          : 'Select Date',
                      subValue: _returnDate != null 
                          ? DateFormat('EEEE').format(_returnDate!) 
                          : 'Tap to select',
                      icon: Icons.calendar_month_rounded,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Passengers
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    label: 'Passengers',
                    value: '$_adults Adult${_adults > 1 ? 's' : ''}',
                    subValue: _children > 0 ? '+ $_children Child' : '',
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      setState(() {
                        _isPassengerExpanded = !_isPassengerExpanded;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Expandable Passenger Selector (Dark)
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Darker bg for expanded area
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adults', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                          onPressed: () {
                            if (_adults > 1) setState(() => _adults--);
                          },
                        ),
                        Text('$_adults', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                          onPressed: () {
                             setState(() => _adults++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _isPassengerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 24),

            // Search Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _searchFlights,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                child: Text(
                  'Search Flights',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A).withOpacity(0.5), // Subtle fill
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White Value Text
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subValue.isNotEmpty)
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFlightResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Available Flights',
            style: GoogleFonts.outfit(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text is white on dark bg
            ),
          ),
          const SizedBox(height: 16),
          ..._flights.map((flight) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FlightDetailsScreen(flightId: flight.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark card for results
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flight.departureAirportCode,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(flight.departureTime),
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${flight.arrivalTime.difference(flight.departureTime).inHours}h ${flight.arrivalTime.difference(flight.departureTime).inMinutes.remainder(60)}m',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Divider(color: Colors.grey[600]),
                                  Transform.rotate(
                                    angle: 1.57,
                                    child: Icon(Icons.flight, color: AppTheme.primaryColor, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              flight.arrivalAirportCode,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(flight.arrivalTime),
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2), 
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.airline_seat_recline_normal, size: 16, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              flight.flightNumber,
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        Text(
                          '\$${flight.basePrice.toInt()}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

