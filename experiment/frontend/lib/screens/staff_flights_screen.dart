import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/staff_service.dart';
import '../models/flight.dart';
import '../models/aviation.dart';
import '../models/booking.dart';
import '../core/theme/app_theme.dart';
import 'staff_main_screen.dart';

class StaffFlightsScreen extends ConsumerStatefulWidget {
  const StaffFlightsScreen({super.key});

  @override
  ConsumerState<StaffFlightsScreen> createState() => _StaffFlightsScreenState();
}

class _StaffFlightsScreenState extends ConsumerState<StaffFlightsScreen> with SingleTickerProviderStateMixin {
  List<Flight> _flights = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFlights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final flights = await staffService.getFlights();
      setState(() {
        _flights = flights;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFlight(Flight flight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete flight ${flight.flightNumber}?'),
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

    if (confirmed == true) {
      try {
        await ref.read(staffServiceProvider).deleteFlight(flight.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Flight deleted successfully')),
          );
          _loadFlights();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            ref.read(staffScaffoldKeyProvider).currentState?.openDrawer();
          },
        ),
        title: const Text('Manage Flights'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateFlightDialog(context),
            tooltip: 'Add Flight',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFlights,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Flights'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFlights,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // All Flights Tab
                          _flights.isEmpty
                              ? const Center(child: Text('No flights found'))
                              : ListView.builder(
                                  itemCount: _flights.length,
                                  padding: const EdgeInsets.all(16),
                                  itemBuilder: (context, index) {
                                    final flight = _flights[index];
                                    return _buildFlightCard(flight);
                                  },
                                ),
                          // Cancelled Flights Tab
                          _buildCancelledFlightsList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(Flight flight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          flight.flightNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${flight.departureAirportCode} → ${flight.arrivalAirportCode}'),
            Text(DateFormat('MMM dd, yyyy HH:mm').format(flight.departureTime)),
            Text('Status: ${flight.status}'),
            Text('Price: \$${flight.basePrice.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditFlightDialog(context, flight),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFlight(flight),
                                ),
                              ],
                            ),
        onTap: () => _showFlightDetails(context, flight),
      ),
    );
  }

  Widget _buildCancelledFlightsList() {
    final cancelledFlights = _flights.where((f) => f.isCancelled).toList();
    
    if (cancelledFlights.isEmpty) {
      return const Center(child: Text('No cancelled flights found'));
    }
    
    return ListView.builder(
      itemCount: cancelledFlights.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final flight = cancelledFlights[index];
        return _buildFlightCard(flight);
      },
    );
  }

  void _showCreateFlightDialog(BuildContext context) async {
    // Controllers
    final flightNumberController = TextEditingController();
    final basePriceController = TextEditingController();
    final gateController = TextEditingController();
    final terminalController = TextEditingController();
    
    // State
    DateTime? departureTime;
    DateTime? arrivalTime;
    String? selectedDepartureCode;
    String? selectedArrivalCode;
    int? selectedAirplaneId;
    
    List<Airport> airports = [];
    List<Airplane> airplanes = [];
    bool isLoadingData = true;

    // Fetch data
    final staffService = ref.read(staffServiceProvider);
    try {
      final results = await Future.wait([
        staffService.getAirports(),
        staffService.getAirplanes(),
      ]);
      airports = results[0] as List<Airport>;
      airplanes = results[1] as List<Airplane>;
      isLoadingData = false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to load data: $e')),
        );
        return; // Don't show dialog if data load fails
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoadingData) {
            return const Center(child: CircularProgressIndicator());
          }

          return AlertDialog(
            title: const Text('Create Flight'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Airports - FIRST STEP (most important)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flight_takeoff, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Select Route',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedDepartureCode,
                                decoration: const InputDecoration(
                                  labelText: 'Departure Airport',
                                  hintText: 'Select airport',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place),
                                ),
                                items: airports.map((a) => DropdownMenuItem(
                                  value: a.code,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        a.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${a.city}, ${a.country}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (value) => setDialogState(() => selectedDepartureCode = value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_forward, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedArrivalCode,
                                decoration: const InputDecoration(
                                  labelText: 'Arrival Airport',
                                  hintText: 'Select airport',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flight_land),
                                ),
                                items: airports.map((a) => DropdownMenuItem(
                                  value: a.code,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        a.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${a.city}, ${a.country}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (value) => setDialogState(() => selectedArrivalCode = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Flight Number
                  TextField(
                    controller: flightNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Flight Number',
                      hintText: 'AA101',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Airplane
                  DropdownButtonFormField<int>(
                    value: selectedAirplaneId,
                    decoration: const InputDecoration(
                      labelText: 'Airplane',
                      border: OutlineInputBorder(),
                    ),
                    items: airplanes.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (${a.model})'),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedAirplaneId = value),
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  ListTile(
                    title: Text(departureTime == null 
                        ? 'Select Departure Time' 
                        : 'Departure: ${DateFormat('MMM dd, yyyy HH:mm').format(departureTime!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final now = DateTime.now();
                      final minDateTime = now.add(const Duration(hours: 2));
                      
                      final date = await showDatePicker(
                        context: context,
                        initialDate: minDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final isToday = date.year == now.year && 
                                       date.month == now.month && 
                                       date.day == now.day;
                        
                        TimeOfDay initialTime;
                        if (isToday) {
                          // If today is selected, set initial time to at least 2 hours from now
                          final minTime = minDateTime;
                          initialTime = TimeOfDay(hour: minTime.hour, minute: minTime.minute);
                        } else {
                          initialTime = TimeOfDay.now();
                        }
                        
                        final time = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );
                        if (time != null) {
                          final selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          
                          // Validate that selected time is at least 2 hours from now
                          if (selectedDateTime.isBefore(minDateTime)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Departure time must be at least 2 hours from now'),
                                ),
                              );
                            }
                            return;
                          }
                          
                          setDialogState(() {
                            departureTime = selectedDateTime;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(arrivalTime == null 
                        ? 'Select Arrival Time' 
                        : 'Arrival: ${DateFormat('MMM dd, yyyy HH:mm').format(arrivalTime!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: departureTime ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: departureTime ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            arrivalTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: basePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Base Price',
                      hintText: '500.0',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gateController,
                          decoration: const InputDecoration(
                            labelText: 'Gate (optional)',
                            hintText: 'A1',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: terminalController,
                          decoration: const InputDecoration(
                            labelText: 'Terminal (optional)',
                            hintText: 'T1',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final basePrice = double.tryParse(basePriceController.text.trim());

                    if (flightNumberController.text.trim().isEmpty ||
                        selectedDepartureCode == null ||
                        selectedArrivalCode == null ||
                        selectedAirplaneId == null ||
                        basePrice == null ||
                        departureTime == null ||
                        arrivalTime == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                      }
                      return;
                    }

                    // Check that departure time is at least 2 hours from now
                    final now = DateTime.now();
                    final minDepartureTime = now.add(const Duration(hours: 2));
                    if (departureTime!.isBefore(minDepartureTime)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Departure time must be at least 2 hours from now'),
                          ),
                        );
                      }
                      return;
                    }

                    if (arrivalTime!.isBefore(departureTime!)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Arrival time must be after departure time')),
                        );
                      }
                      return;
                    }

                    await staffService.createFlight(
                      flightNumber: flightNumberController.text.trim(),
                      departureAirportCode: selectedDepartureCode!,
                      arrivalAirportCode: selectedArrivalCode!,
                      airplaneId: selectedAirplaneId!,
                      departureTime: departureTime!,
                      arrivalTime: arrivalTime!,
                      basePrice: basePrice,
                      gate: gateController.text.trim().isEmpty ? null : gateController.text.trim(),
                      terminal: terminalController.text.trim().isEmpty ? null : terminalController.text.trim(),
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadFlights();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flight created successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditFlightDialog(BuildContext context, Flight flight) async {
    final statusController = TextEditingController(text: flight.status);
    final gateController = TextEditingController(text: flight.gate ?? '');
    final terminalController = TextEditingController(text: flight.terminal ?? '');
    DateTime? departureTime = flight.departureTime;
    DateTime? arrivalTime = flight.arrivalTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Flight ${flight.flightNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: flight.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SCHEDULED', child: Text('SCHEDULED')),
                    DropdownMenuItem(value: 'BOARDING', child: Text('BOARDING')),
                    DropdownMenuItem(value: 'DELAYED', child: Text('DELAYED')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                    DropdownMenuItem(value: 'DEPARTED', child: Text('DEPARTED')),
                    DropdownMenuItem(value: 'LANDED', child: Text('LANDED')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      statusController.text = value;
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(departureTime == null 
                      ? 'Select Departure Time' 
                      : 'Departure: ${DateFormat('MMM dd, yyyy HH:mm').format(departureTime!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: departureTime ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(departureTime ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          departureTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(arrivalTime == null 
                      ? 'Select Arrival Time' 
                      : 'Arrival: ${DateFormat('MMM dd, yyyy HH:mm').format(arrivalTime!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: arrivalTime ?? DateTime.now(),
                      firstDate: departureTime ?? DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(arrivalTime ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          arrivalTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gateController,
                  decoration: const InputDecoration(
                    labelText: 'Gate (optional)',
                    hintText: 'A1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: terminalController,
                  decoration: const InputDecoration(
                    labelText: 'Terminal (optional)',
                    hintText: 'T1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                statusController.dispose();
                gateController.dispose();
                terminalController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (arrivalTime != null && departureTime != null && arrivalTime!.isBefore(departureTime!)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Arrival time must be after departure time')),
                      );
                    }
                    return;
                  }

                  final staffService = ref.read(staffServiceProvider);
                  await staffService.updateFlight(
                    flightId: flight.id,
                    status: statusController.text != flight.status ? statusController.text : null,
                    gate: gateController.text.trim() != (flight.gate ?? '') ? gateController.text.trim() : null,
                    terminal: terminalController.text.trim() != (flight.terminal ?? '') ? terminalController.text.trim() : null,
                    departureTime: departureTime != flight.departureTime ? departureTime : null,
                    arrivalTime: arrivalTime != flight.arrivalTime ? arrivalTime : null,
                  );
                  
                  statusController.dispose();
                  gateController.dispose();
                  terminalController.dispose();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadFlights();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flight updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlightDetails(BuildContext context, Flight flight) {
    final parentContext = context; // Save parent context
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Flight ${flight.flightNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Route: ${flight.departureAirportCode} → ${flight.arrivalAirportCode}'),
              Text('Departure: ${DateFormat('MMM dd, yyyy HH:mm').format(flight.departureTime)}'),
              Text('Arrival: ${DateFormat('MMM dd, yyyy HH:mm').format(flight.arrivalTime)}'),
              Text('Status: ${flight.status}'),
              Text('Price: \$${flight.basePrice.toStringAsFixed(2)}'),
              if (flight.gate != null) Text('Gate: ${flight.gate}'),
              if (flight.terminal != null) Text('Terminal: ${flight.terminal}'),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showFlightPassengers(parentContext, flight);
            },
            icon: const Icon(Icons.people, size: 18),
            label: const Text('View Passengers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFlightPassengers(BuildContext context, Flight flight) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final staffService = ref.read(staffServiceProvider);
      final bookings = await staffService.getBookingsByFlight(flight.id);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Flatten bookings to get all passengers (tickets)
      final List<Map<String, dynamic>> passengers = [];
      for (var booking in bookings) {
        for (var ticket in booking.tickets) {
          passengers.add({
            'name': ticket.passengerName,
            'seat': ticket.seatNumber,
            'pnr': booking.pnr,
            'status': booking.status,
            'ticketNumber': ticket.ticketNumber,
            'booking': booking, // Keep reference for actions if needed
          });
        }
      }

      // Sort by seat number
      passengers.sort((a, b) => (a['seat'] as String).compareTo(b['seat'] as String));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Passengers (${passengers.length}) - ${flight.flightNumber}'),
          content: SizedBox(
            width: double.maxFinite,
            child: passengers.isEmpty
                ? const Text('No passengers found for this flight.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: passengers.length,
                    itemBuilder: (context, index) {
                      final p = passengers[index];
                      final isCancelled = p['status'] == 'CANCELLED';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCancelled ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                            child: Text(
                              (p['seat'] as String).replaceAll(RegExp(r'\d+'), ''), // Seat letter as avatar? Or just initials
                              style: TextStyle(color: isCancelled ? Colors.red : Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            p['name'], 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seat: ${p['seat']}  •  PNR: ${p['pnr']}'),
                              Text('Ticket: ${p['ticketNumber']}'),
                            ],
                          ),
                          trailing: isCancelled
                              ? const Chip(label: Text('Cancelled', style: TextStyle(fontSize: 10)), backgroundColor: Colors.redAccent)
                              : IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    // Option to view full booking details
                                     _showBookingDetails(context, p['booking'] as Booking);
                                  },
                                ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading passengers: $e')),
      );
    }
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    // Show booking details in a dialog with full information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking ${booking.pnr}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PNR: ${booking.pnr}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Status: ${booking.status}'),
              Text('Total Price: \$${booking.totalPrice.toStringAsFixed(2)}'),
              if (booking.flight != null) ...[
                const SizedBox(height: 8),
                Text('Flight: ${booking.flight!.flightNumber}'),
                Text('Route: ${booking.flight!.departureAirportCode} → ${booking.flight!.arrivalAirportCode}'),
                Text('Departure: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.flight!.departureTime)}'),
              ],
              const SizedBox(height: 16),
              const Text('Tickets:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...booking.tickets.map((ticket) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('${ticket.passengerName} - Seat: ${ticket.seatNumber}'),
                  )),
            ],
          ),
        ),
        actions: [
          if (!booking.isCancelled)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Cancel'),
                    content: const Text('Are you sure you want to cancel this booking?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    final staffService = ref.read(staffServiceProvider);
                    await staffService.cancelBooking(booking.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Booking'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
