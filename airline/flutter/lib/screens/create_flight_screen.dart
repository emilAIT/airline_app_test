import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class CreateFlightScreen extends StatefulWidget {
  final List<dynamic> airports;
  final List<dynamic> airplanes;

  const CreateFlightScreen({
    super.key,
    required this.airports,
    required this.airplanes,
  });

  @override
  State<CreateFlightScreen> createState() => _CreateFlightScreenState();
}

class _CreateFlightScreenState extends State<CreateFlightScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _flightNumberController = TextEditingController();
  final _priceController = TextEditingController();

  int? _selectedOriginId;
  int? _selectedDestinationId;
  int? _selectedAirplaneId;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  String? _gate;
  String? _terminal;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Debug: Print received data
    print('CreateFlightScreen - Airports count: ${widget.airports.length}');
    print('CreateFlightScreen - Airplanes count: ${widget.airplanes.length}');
    if (widget.airports.isNotEmpty) {
      print('First airport: ${widget.airports[0]}');
    }
    if (widget.airplanes.isNotEmpty) {
      print('First airplane: ${widget.airplanes[0]}');
    }
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartureDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EldiyarTheme.primaryBlue,
              onPrimary: EldiyarTheme.darkerBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: EldiyarTheme.primaryBlue,
                onPrimary: EldiyarTheme.darkerBackground,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() {
          _departureDate = date;
          _departureTime = time;
        });
      }
    }
  }

  Future<void> _selectArrivalDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EldiyarTheme.primaryBlue,
              onPrimary: EldiyarTheme.darkerBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: EldiyarTheme.primaryBlue,
                onPrimary: EldiyarTheme.darkerBackground,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() {
          _arrivalDate = date;
          _arrivalTime = time;
        });
      }
    }
  }

  Future<void> _createFlight() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOriginId == null ||
        _selectedDestinationId == null ||
        _selectedAirplaneId == null ||
        _departureDate == null ||
        _departureTime == null ||
        _arrivalDate == null ||
        _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: EldiyarTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final departureDateTime = DateTime(
        _departureDate!.year,
        _departureDate!.month,
        _departureDate!.day,
        _departureTime!.hour,
        _departureTime!.minute,
      );
      final arrivalDateTime = DateTime(
        _arrivalDate!.year,
        _arrivalDate!.month,
        _arrivalDate!.day,
        _arrivalTime!.hour,
        _arrivalTime!.minute,
      );

      final flightData = {
        'flight_number': _flightNumberController.text.trim(),
        'origin_id': _selectedOriginId,
        'destination_id': _selectedDestinationId,
        'airplane_id': _selectedAirplaneId,
        'departure_time': departureDateTime.toIso8601String(),
        'arrival_time': arrivalDateTime.toIso8601String(),
        'base_price': double.parse(_priceController.text.trim()),
        'gate': _gate?.trim().isEmpty == true ? null : _gate?.trim(),
        'terminal': _terminal?.trim().isEmpty == true
            ? null
            : _terminal?.trim(),
      };

      print('Creating flight with data: $flightData');
      await _api.createFlight(flightData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight created successfully!'),
            backgroundColor: EldiyarTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        String errorMessage = 'Error creating flight: $e';
        // Provide more helpful error messages
        if (e.toString().contains('Failed to fetch') ||
            e.toString().contains('ClientException')) {
          errorMessage =
              'Cannot connect to server. Please check:\n'
              '1. Backend is running on http://127.0.0.1:8001\n'
              '2. You are logged in as staff\n'
              '3. Check browser console for details';
        } else if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Authentication failed. Please log in again.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid flight data. Please check all fields.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: EldiyarTheme.errorRed,
            duration: const Duration(seconds: 5),
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
                        'Create Flight',
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
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Warning messages if lists are empty
                      if (widget.airports.isEmpty || widget.airplanes.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: EldiyarTheme.accentTeal,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Setup Required',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: EldiyarTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.airports.isEmpty &&
                                              widget.airplanes.isEmpty
                                          ? 'Please add airports and airplanes first from the Staff Dashboard.'
                                          : widget.airports.isEmpty
                                          ? 'Please add airports first from the Staff Dashboard.'
                                          : 'Please add airplanes first from the Staff Dashboard.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: EldiyarTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _flightNumberController,
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Flight Number *',
                                  prefixIcon: Icon(
                                    Icons.flight,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter flight number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedOriginId,
                                decoration: InputDecoration(
                                  labelText: 'Origin Airport *',
                                  hintText: widget.airports.isEmpty
                                      ? 'No airports available. Add airports first.'
                                      : 'Select origin airport',
                                  prefixIcon: const Icon(
                                    Icons.flight_takeoff,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                dropdownColor: EldiyarTheme.cardBackground,
                                items: widget.airports.isEmpty
                                    ? [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          enabled: false,
                                          child: Text(
                                            'No airports available',
                                            style: TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : widget.airports.map<
                                        DropdownMenuItem<int>
                                      >((airport) {
                                        final airportId = airport['id'] is int
                                            ? airport['id']
                                            : int.tryParse(
                                                airport['id'].toString(),
                                              );
                                        return DropdownMenuItem<int>(
                                          value: airportId,
                                          child: Text(
                                            '${airport['code']} - ${airport['name']}',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                onChanged: widget.airports.isEmpty
                                    ? null
                                    : (value) => setState(
                                        () => _selectedOriginId = value,
                                      ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select origin airport';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedDestinationId,
                                decoration: InputDecoration(
                                  labelText: 'Destination Airport *',
                                  hintText: widget.airports.isEmpty
                                      ? 'No airports available. Add airports first.'
                                      : 'Select destination airport',
                                  prefixIcon: const Icon(
                                    Icons.flight_land,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                dropdownColor: EldiyarTheme.cardBackground,
                                items: widget.airports.isEmpty
                                    ? [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          enabled: false,
                                          child: Text(
                                            'No airports available',
                                            style: TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : widget.airports.map<
                                        DropdownMenuItem<int>
                                      >((airport) {
                                        final airportId = airport['id'] is int
                                            ? airport['id']
                                            : int.tryParse(
                                                airport['id'].toString(),
                                              );
                                        return DropdownMenuItem<int>(
                                          value: airportId,
                                          child: Text(
                                            '${airport['code']} - ${airport['name']}',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                onChanged: widget.airports.isEmpty
                                    ? null
                                    : (value) => setState(
                                        () => _selectedDestinationId = value,
                                      ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select destination airport';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedAirplaneId,
                                decoration: InputDecoration(
                                  labelText: 'Airplane *',
                                  hintText: widget.airplanes.isEmpty
                                      ? 'No airplanes available. Add airplanes first.'
                                      : 'Select airplane',
                                  prefixIcon: const Icon(
                                    Icons.airplanemode_active,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                dropdownColor: EldiyarTheme.cardBackground,
                                items: widget.airplanes.isEmpty
                                    ? [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          enabled: false,
                                          child: Text(
                                            'No airplanes available',
                                            style: TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : widget.airplanes.map<
                                        DropdownMenuItem<int>
                                      >((airplane) {
                                        final airplaneId = airplane['id'] is int
                                            ? airplane['id']
                                            : int.tryParse(
                                                airplane['id'].toString(),
                                              );
                                        return DropdownMenuItem<int>(
                                          value: airplaneId,
                                          child: Text(
                                            '${airplane['model']} (${airplane['total_seats']} seats)',
                                            style: const TextStyle(
                                              color: EldiyarTheme.textPrimary,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                onChanged: widget.airplanes.isEmpty
                                    ? null
                                    : (value) => setState(
                                        () => _selectedAirplaneId = value,
                                      ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select airplane';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _priceController,
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Base Price (USD) *',
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _selectDepartureDateTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Departure Date & Time *',
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: EldiyarTheme.primaryBlue,
                                    ),
                                  ),
                                  child: Text(
                                    _departureDate == null ||
                                            _departureTime == null
                                        ? 'Select departure date and time'
                                        : '${DateFormat('yyyy-MM-dd').format(_departureDate!)} ${_departureTime!.format(context)}',
                                    style: const TextStyle(
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _selectArrivalDateTime,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Arrival Date & Time *',
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: EldiyarTheme.primaryBlue,
                                    ),
                                  ),
                                  child: Text(
                                    _arrivalDate == null || _arrivalTime == null
                                        ? 'Select arrival date and time'
                                        : '${DateFormat('yyyy-MM-dd').format(_arrivalDate!)} ${_arrivalTime!.format(context)}',
                                    style: const TextStyle(
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                onChanged: (value) =>
                                    setState(() => _gate = value),
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Gate (optional)',
                                  prefixIcon: Icon(
                                    Icons.door_front_door,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                onChanged: (value) =>
                                    setState(() => _terminal = value),
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Terminal (optional)',
                                  prefixIcon: Icon(
                                    Icons.business,
                                    color: EldiyarTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GlowButton(
                                label: 'Create Flight',
                                icon: Icons.add,
                                onPressed: _isCreating ? null : _createFlight,
                                isLoading: _isCreating,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
