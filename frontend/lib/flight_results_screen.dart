import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'flight_details_screen.dart';
import 'flight_search_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? searchParams;

  const FlightResultsScreen({super.key, this.searchParams});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  int _selectedDateIndex = 3; // Default to middle
  late List<DateTime> _availableDates;
  bool _isLoading = true;
  List<Map<String, dynamic>> _flights = [];

  @override
  void initState() {
    super.initState();
    
    // Generate dates around search date
    final searchDate = (widget.searchParams?['departureDate'] is DateTime)
        ? widget.searchParams!['departureDate'] as DateTime
        : DateTime.now();
        
    _availableDates = List.generate(
      7,
      (index) => searchDate.subtract(Duration(days: 3 - index)),
    );
    
    _loadFlights();
  }

  void _loadFlights() {
    // Simulate API delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
           // Mock filtering logic based on params could go here
           // For now, we generate results that match the destination if provided
           final toCity = widget.searchParams?['toCity'] ?? 'New York';
           final fromCode = widget.searchParams?['fromCode'] ?? 'IST';
           final toCode = widget.searchParams?['toCode'] ?? 'JFK';
           
           _flights = [
             {
               'flightNumber': 'TK 0001',
               'depTime': '13:05',
               'arrTime': '17:35',
               'duration': '11h 30m',
               'price': '\$720',
               'highlight': 'Best Value',
               'isCheapest': false,
             },
             {
               'flightNumber': 'TK 0011',
               'depTime': '18:10',
               'arrTime': '22:45',
               'duration': '11h 35m',
               'price': '\$850',
               'highlight': 'Fastest',
               'isCheapest': false,
             },
             {
               'flightNumber': 'TK 1982',
               'depTime': '02:00',
               'arrTime': '06:30',
               'duration': '11h 30m',
               'price': '\$680',
               'highlight': null,
               'isCheapest': true,
             },
             {
               'flightNumber': 'TK 0003',
               'depTime': '07:20',
               'arrTime': '11:55',
               'duration': '11h 35m',
               'price': '\$1,100',
               'highlight': null,
               'isCheapest': false,
             },
           ];
           _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Basic Header Data
    final fromCode = widget.searchParams?['fromCode'] ?? 'IST';
    final toCode = widget.searchParams?['toCode'] ?? 'JFK';
    final passengers = widget.searchParams?['passengerCount'] ?? 1;
    
    String dateStr = '12 Oct';
    if (widget.searchParams?['departureDate'] != null) {
      if (widget.searchParams!['departureDate'] is DateTime) {
        dateStr = DateFormat('d MMM').format(widget.searchParams!['departureDate'] as DateTime);
      } else if (widget.searchParams!['departureDate'] is String) {
        dateStr = widget.searchParams!['departureDate'];
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF0B1E3B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              '$fromCode - $toCode',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '$dateStr, $passengers Passenger${passengers > 1 ? 's' : ''}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
            onPressed: () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: (widget.searchParams?['departureDate'] is DateTime)
                    ? widget.searchParams!['departureDate'] as DateTime
                    : DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              
              if (newDate != null) {
                // Navigate back to search with new date
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlightSearchScreen(
                      initialSearchParams: {
                        ...?widget.searchParams,
                        'departureDate': newDate,
                      },
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircularProgressIndicator(color: Color(0xFFC59D5F)),
                   const SizedBox(height: 16),
                   Text(
                     'Searching best flights...',
                     style: GoogleFonts.manrope(
                       fontSize: 16, 
                       color: const Color(0xFF0B1E3B), 
                       fontWeight: FontWeight.w600
                     ),
                   ),
                ],
              ),
            )
          : Column(
              children: [
                // Date Carousel
                Container(
                  color: const Color(0xFF0B1E3B),
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _availableDates.length,
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected = index == _selectedDateIndex;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDateIndex = index;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Searching flights for ${DateFormat('dd MMM').format(date)}',
                                  style: GoogleFonts.manrope(),
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: const Color(0xFF0B1E3B),
                              ),
                            );
                          },
                          child: Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFC59D5F) : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('d').format(date),
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF0B1E3B) : Colors.white,
                                  ),
                                ),
                                Text(
                                  DateFormat('E').format(date),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: isSelected ? const Color(0xFF0B1E3B) : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Filter & Sort Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_flights.length} flights found',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        children: [
                          _buildFilterChip(Icons.sort_rounded, 'Sort'),
                          const SizedBox(width: 8),
                          _buildFilterChip(Icons.tune_rounded, 'Filter'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Flight List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _flights.length,
                    itemBuilder: (context, index) {
                      final flight = _flights[index];
                      return _buildFlightCard(
                        flightNumber: flight['flightNumber'],
                        depTime: flight['depTime'],
                        arrTime: flight['arrTime'],
                        duration: flight['duration'],
                        price: flight['price'],
                        highlight: flight['highlight'],
                        isCheapest: flight['isCheapest'],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B1E3B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1E3B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard({
    required String flightNumber,
    required String depTime,
    required String arrTime,
    required String duration,
    required String price,
    String? highlight,
    bool isCheapest = false,
  }) {
    // Helper access
    final fromCode = widget.searchParams?['fromCode'] ?? 'IST';
    final toCode = widget.searchParams?['toCode'] ?? 'JFK';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlightDetailsScreen(
                flightData: {
                  'flightNumber': flightNumber,
                  'from': fromCode,
                  'to': toCode,
                  'departureTime': depTime,
                  'arrivalTime': arrTime,
                  'date': widget.searchParams?['departureDate'],
                  'duration': duration,
                  'price': double.tryParse(price.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
                  'airline': 'Turkish Airlines',
                  'aircraft': 'Boeing 777-300ER',
                },
              ),
            ),
          );
        },
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isCheapest 
                    ? const BorderSide(color: Color(0xFFC59D5F), width: 1.5)
                    : BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Upper Row: Times & Route
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              depTime,
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1E3B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fromCode,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  duration,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                                    Transform.rotate(
                                      angle: 1.5708,
                                      child: const Icon(Icons.flight_rounded,
                                          size: 20, color: Color(0xFFC59D5F)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Direct',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arrTime,
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1E3B),
                                ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              toCode,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    
                    // Lower Row: Flight Info & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff_rounded, size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text(
                              flightNumber,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (highlight != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  highlight,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Economy',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  price,
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1E3B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC59D5F)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isCheapest)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC59D5F),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Lowest Price',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}