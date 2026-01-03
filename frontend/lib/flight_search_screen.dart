import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'flight_results_screen.dart';

class FlightSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSearchParams;
  
  const FlightSearchScreen({super.key, this.initialSearchParams});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _tripType = 'round-trip';
  int _passengerCount = 1;
  String _cabinClass = 'Economy';
  
  // Selection States
  String _fromCode = 'IST';
  String _fromCity = 'Istanbul';
  String _fromAirport = 'Istanbul Airport';
  
  String _toCode = 'JFK';
  String _toCity = 'New York';
  String _toAirport = 'John F. Kennedy Intl.';
  
  DateTime _departureDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _returnDate = DateTime.now().add(const Duration(days: 8));

  // Multi-City state
  List<Map<String, dynamic>> _multiCityFlights = [
    {
      'from': 'IST',
      'fromCity': 'Istanbul',
      'to': 'JFK',
      'toCity': 'New York',
      'date': DateTime.now().add(const Duration(days: 7)),
    },
    {
      'from': 'JFK',
      'fromCity': 'New York',
      'to': 'LAX',
      'toCity': 'Los Angeles',
      'date': DateTime.now().add(const Duration(days: 10)),
    },
  ];

  // Switch states
  bool _payWithMiles = false;
  bool _flexibleDates = false;

  // Mock Data
  final List<Map<String, String>> _airports = [
    {'code': 'IST', 'city': 'Istanbul', 'name': 'Istanbul Airport'},
    {'code': 'JFK', 'city': 'New York', 'name': 'John F. Kennedy Intl.'},
    {'code': 'LHR', 'city': 'London', 'name': 'Heathrow Airport'},
    {'code': 'CDG', 'city': 'Paris', 'name': 'Charles de Gaulle'},
    {'code': 'DXB', 'city': 'Dubai', 'name': 'Dubai International'},
    {'code': 'FRA', 'city': 'Frankfurt', 'name': 'Frankfurt Airport'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with passed params if available
    if (widget.initialSearchParams != null) {
      final params = widget.initialSearchParams!;
      _fromCode = params['fromCode'] ?? _fromCode;
      _fromCity = params['fromCity'] ?? _fromCity;
      _toCode = params['toCode'] ?? _toCode;
      _toCity = params['toCity'] ?? _toCity;
      _departureDate = params['departureDate'] is DateTime 
          ? params['departureDate'] 
          : _departureDate;
      _returnDate = params['returnDate'] is DateTime ? params['returnDate'] : _returnDate;
      _passengerCount = params['passengerCount'] ?? _passengerCount;
      _cabinClass = params['cabinClass'] ?? _cabinClass;
      _tripType = params['tripType'] ?? _tripType;
      
      // Set tab index based on trip type
      if (_tripType == 'round-trip') _tabController.index = 0;
      else if (_tripType == 'one-way') _tabController.index = 1;
      else if (_tripType == 'multi-city') {
        _tabController.index = 2;
        if (params['multiCityFlights'] != null) {
          _multiCityFlights = List<Map<String, dynamic>>.from(params['multiCityFlights']);
        }
      }
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _tripType = 'round-trip';
          } else if (_tabController.index == 1) {
            _tripType = 'one-way';
          } else {
            _tripType = 'multi-city';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final tempCode = _fromCode;
      final tempCity = _fromCity;
      final tempAirport = _fromAirport;
      
      _fromCode = _toCode;
      _fromCity = _toCity;
      _fromAirport = _toAirport;
      
      _toCode = tempCode;
      _toCity = tempCity;
      _toAirport = tempAirport;
    });
  }

  Future<void> _selectDate(bool isDeparture) async {
    final initialDate = isDeparture ? _departureDate : (_returnDate ?? _departureDate);
    final firstDate = isDeparture ? DateTime.now() : _departureDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B1E3B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1E3B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          // Reset return date if it's before new departure date
          if (_returnDate != null && _returnDate!.isBefore(_departureDate)) {
            _returnDate = _departureDate.add(const Duration(days: 7));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _addMultiCityFlight() {
    if (_multiCityFlights.length < 5) {
      setState(() {
        _multiCityFlights.add({
          'from': 'LAX',
          'fromCity': 'Los Angeles',
          'to': 'MIA',
          'toCity': 'Miami',
          'date': DateTime.now().add(Duration(days: 7 + (_multiCityFlights.length * 3))),
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum 5 flights allowed',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  void _removeMultiCityFlight(int index) {
    if (_multiCityFlights.length > 2) {
      setState(() {
        _multiCityFlights.removeAt(index);
      });
    }
  }

  Future<void> _selectMultiCityDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _multiCityFlights[index]['date'],
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B1E3B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1E3B),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _multiCityFlights[index]['date'] = picked;
      });
    }
  }

  void _showAirportSelector(BuildContext context, int? multiCityIndex, String type) {
    final bool isFrom = type == 'from';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrom ? 'Select Origin' : 'Select Destination',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B1E3B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _airports.length,
                itemBuilder: (context, index) {
                  final airport = _airports[index];
                  return ListTile(
                    leading: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFC59D5F)),
                    title: Text(
                      '${airport['city']} (${airport['code']})',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B1E3B),
                      ),
                    ),
                    subtitle: Text(
                      airport['name']!,
                      style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                    ),
                    onTap: () {
                      setState(() {
                        if (multiCityIndex != null) {
                          if (isFrom) {
                            _multiCityFlights[multiCityIndex]['from'] = airport['code']!;
                            _multiCityFlights[multiCityIndex]['fromCity'] = airport['city']!;
                          } else {
                            _multiCityFlights[multiCityIndex]['to'] = airport['code']!;
                            _multiCityFlights[multiCityIndex]['toCity'] = airport['city']!;
                          }
                        } else {
                          if (isFrom) {
                            _fromCode = airport['code']!;
                            _fromCity = airport['city']!;
                            _fromAirport = airport['name']!;
                          } else {
                            _toCode = airport['code']!;
                            _toCity = airport['city']!;
                            _toAirport = airport['name']!;
                          }
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassengerAndClassPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passengers',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adults',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _passengerCount > 1 
                            ? () => setModalState(() => setState(() => _passengerCount--)) 
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text(
                        '$_passengerCount',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _passengerCount < 9
                            ? () => setModalState(() => setState(() => _passengerCount++))
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Cabin Class',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ['Economy', 'Business', 'First'].map((cls) {
                  final isSelected = _cabinClass == cls;
                  return ChoiceChip(
                    label: Text(cls),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => setState(() => _cabinClass = cls));
                      }
                    },
                    selectedColor: const Color(0xFF0B1E3B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: const Color(0xFF0B1E3B),
        title: Text(
          'Book a Flight',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Tab Bar Container
          Container(
            color: const Color(0xFF0B1E3B),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFFC59D5F),
                  borderRadius: BorderRadius.circular(24),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Round Trip'),
                  Tab(text: 'One Way'),
                  Tab(text: 'Multi City'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_tripType != 'multi-city') ...[
                    // Route Selection Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showAirportSelector(context, null, 'from'),
                              child: _buildLocationRow(
                                icon: Icons.flight_takeoff_rounded,
                                label: 'From',
                                code: _fromCode,
                                city: _fromCity,
                                airport: _fromAirport,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  const Expanded(child: Divider(height: 1, color: Color(0xFFE2E8F0))),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7F9),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF0B1E3B), size: 20),
                                      onPressed: _swapLocations,
                                    ),
                                  ),
                                  const Expanded(child: Divider(height: 1, color: Color(0xFFE2E8F0))),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAirportSelector(context, null, 'to'),
                              child: _buildLocationRow(
                                icon: Icons.flight_land_rounded,
                                label: 'To',
                                code: _toCode,
                                city: _toCity,
                                airport: _toAirport,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dates Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(true),
                                child: _buildDateSelector(
                                  label: 'Departure',
                                  date: _departureDate,
                                ),
                              ),
                            ),
                            
                            // RETURN DATE - Only for Round Trip
                            if (_tripType == 'round-trip') ...[
                              Container(
                                width: 1,
                                height: 48,
                                color: const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child: _buildDateSelector(
                                    label: 'Return',
                                    date: _returnDate,
                                    isReturn: true,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    
                    // Loop through all multi-city flights
                    ...List.generate(_multiCityFlights.length, (index) {
                      final flight = _multiCityFlights[index];
                      
                      return Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Flight ${index + 1}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0B1E3B),
                                        ),
                                      ),
                                      if (_multiCityFlights.length > 2)
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 20),
                                          onPressed: () => _removeMultiCityFlight(index),
                                          color: const Color(0xFFBA1A1A),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  GestureDetector(
                                    onTap: () => _showAirportSelector(context, index, 'from'),
                                    child: _buildLocationRow(
                                      icon: Icons.flight_takeoff_rounded,
                                      label: 'From',
                                      code: flight['from'],
                                      city: flight['fromCity'],
                                      airport: '${flight['fromCity']} Airport',
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  GestureDetector(
                                    onTap: () => _showAirportSelector(context, index, 'to'),
                                    child: _buildLocationRow(
                                      icon: Icons.flight_land_rounded,
                                      label: 'To',
                                      code: flight['to'],
                                      city: flight['toCity'],
                                      airport: '${flight['toCity']} Airport',
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  GestureDetector(
                                    onTap: () => _selectMultiCityDate(index),
                                    child: _buildDateSelector(
                                      label: 'Departure',
                                      date: flight['date'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    
                    // Add Flight Button
                    OutlinedButton.icon(
                      onPressed: _addMultiCityFlight,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(
                        'Add Another Flight',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1E3B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  // MULTI-CITY EXTRA FLIGHT (Handled above in if block)
                  
                  const SizedBox(height: 16),

                  // Passenger & Class Card
                  Card(
                    child: InkWell(
                      onTap: _showPassengerAndClassPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: Color(0xFFC59D5F), size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Passengers & Class', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_passengerCount Adult, $_cabinClass',
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B1E3B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSwitchOption(
                        'Pay with Miles',
                        _payWithMiles,
                        (value) {
                          setState(() => _payWithMiles = value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _payWithMiles ? 'Miles payment enabled' : 'Miles payment disabled',
                                style: GoogleFonts.manrope(),
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF0B1E3B),
                            ),
                          );
                        },
                      ),
                      _buildSwitchOption(
                        'Flexible dates',
                        _flexibleDates,
                        (value) {
                          setState(() => _flexibleDates = value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _flexibleDates ? 'Flexible dates enabled - Searching ±3 days' : 'Exact dates only',
                                style: GoogleFonts.manrope(),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF0B1E3B),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Search Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlightResultsScreen(
                            searchParams: {
                              'fromCode': _fromCode,
                              'toCode': _toCode,
                              'departureDate': _departureDate,
                              'returnDate': _returnDate,
                              'passengerCount': _passengerCount,
                              'cabinClass': _cabinClass,
                              'tripType': _tripType,
                              'fromCity': _fromCity, 
                              'toCity': _toCity,
                              'multiCityFlights': _tripType == 'multi-city' ? _multiCityFlights : null,
                              'payWithMiles': _payWithMiles,
                              'flexibleDates': _flexibleDates,
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: const Color(0xFF0B1E3B).withOpacity(0.4),
                      elevation: 8,
                    ),
                    child: const Text('SEARCH FLIGHTS'),
                  ),

                  const SizedBox(height: 32),
                  
                  // Recent Searches
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B1E3B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRecentSearchChip('LHR', 'London'),
                        const SizedBox(width: 12),
                        _buildRecentSearchChip('CDG', 'Paris'),
                        const SizedBox(width: 12),
                        _buildRecentSearchChip('DXB', 'Dubai'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String code,
    required String city,
    required String airport,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFC59D5F), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(code,
                      style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1E3B))),
                   const SizedBox(width: 8),
                   Text(city,
                      style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0B1E3B))),
                ],
              ),
              Text(airport,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    bool isReturn = false,
  }) {
    if (date == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            'Select Date',
             style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              DateFormat('dd').format(date),
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B1E3B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM').format(date),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0B1E3B),
              ),
            ),
          ],
        ),
        Text(
          DateFormat('EEEE').format(date),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption(String text, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 40,
          child: Switch(
            value: value,
            activeColor: const Color(0xFFC59D5F),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B1E3B),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchChip(String code, String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IST ➔ $code',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              Text(
                'Economy • 1 Adult',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}