import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class EditFlightScreen extends StatefulWidget {
  final Map<String, dynamic> flight;
  final List<dynamic> airports;
  final List<dynamic> airplanes;

  const EditFlightScreen({
    super.key,
    required this.flight,
    required this.airports,
    required this.airplanes,
  });

  @override
  State<EditFlightScreen> createState() => _EditFlightScreenState();
}

class _EditFlightScreenState extends State<EditFlightScreen> {
  final ApiService _api = ApiService();
  final _priceController = TextEditingController();
  
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  String? _gate;
  String? _terminal;
  String? _status;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final departure = DateTime.parse(widget.flight['departure_time']);
    final arrival = DateTime.parse(widget.flight['arrival_time']);
    _departureDate = departure;
    _departureTime = TimeOfDay.fromDateTime(departure);
    _arrivalDate = arrival;
    _arrivalTime = TimeOfDay.fromDateTime(arrival);
    _priceController.text = widget.flight['base_price'].toString();
    _gate = widget.flight['gate'];
    _terminal = widget.flight['terminal'];
    _status = widget.flight['status'];
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartureDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
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
        initialTime: _departureTime ?? TimeOfDay.now(),
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
      initialDate: _arrivalDate ?? DateTime.now(),
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
        initialTime: _arrivalTime ?? TimeOfDay.now(),
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

  Future<void> _updateFlight() async {
    if (_departureDate == null ||
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

    setState(() => _isUpdating = true);
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

      final updateData = <String, dynamic>{
        'departure_time': departureDateTime.toIso8601String(),
        'arrival_time': arrivalDateTime.toIso8601String(),
        'base_price': double.parse(_priceController.text.trim()),
        'gate': _gate?.trim().isEmpty == true ? null : _gate?.trim(),
        'terminal': _terminal?.trim().isEmpty == true ? null : _terminal?.trim(),
      };

      if (_status != null) {
        updateData['status'] = _status;
      }

      await _api.updateFlight(widget.flight['id'], updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight updated successfully!'),
            backgroundColor: EldiyarTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating flight: $e'),
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
                    Expanded(
                      child: Text(
                        'Edit Flight: ${widget.flight['flight_number']}',
                        style: const TextStyle(
                          fontSize: 20,
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
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${widget.flight['origin']['code']} → ${widget.flight['destination']['code']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: EldiyarTheme.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _priceController,
                          style: const TextStyle(
                            color: EldiyarTheme.textPrimary,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Base Price (USD)',
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: EldiyarTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDepartureDateTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Departure Date & Time',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: EldiyarTheme.primaryBlue,
                              ),
                            ),
                            child: Text(
                              _departureDate == null || _departureTime == null
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
                              labelText: 'Arrival Date & Time',
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
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Flight Status',
                            prefixIcon: Icon(
                              Icons.info,
                              color: EldiyarTheme.primaryBlue,
                            ),
                          ),
                          style: const TextStyle(
                            color: EldiyarTheme.textPrimary,
                          ),
                          dropdownColor: EldiyarTheme.cardBackground,
                          items: const [
                            'SCHEDULED',
                            'BOARDING',
                            'DELAYED',
                            'CANCELLED',
                            'DEPARTED',
                            'LANDED',
                          ].map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: EldiyarTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _status = value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _gate,
                          onChanged: (value) => setState(() => _gate = value),
                          style: const TextStyle(
                            color: EldiyarTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Gate',
                            prefixIcon: Icon(
                              Icons.door_front_door,
                              color: EldiyarTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _terminal,
                          onChanged: (value) =>
                              setState(() => _terminal = value),
                          style: const TextStyle(
                            color: EldiyarTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Terminal',
                            prefixIcon: Icon(
                              Icons.business,
                              color: EldiyarTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlowButton(
                          label: 'Update Flight',
                          icon: Icons.save,
                          onPressed: _isUpdating ? null : _updateFlight,
                          isLoading: _isUpdating,
                        ),
                      ],
                    ),
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

