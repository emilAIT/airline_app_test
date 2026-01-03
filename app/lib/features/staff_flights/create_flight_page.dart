import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/api/airports_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/airport.dart';
import '../../shared/models/airplane.dart';
import '../../shared/models/enums.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';

class CreateFlightPage extends StatefulWidget {
  const CreateFlightPage({super.key});

  @override
  State<CreateFlightPage> createState() => _CreateFlightPageState();
}

class _CreateFlightPageState extends State<CreateFlightPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  late final AirportsApi _airportsApi;
  
  final _flightNumberController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _gateController = TextEditingController();
  final _terminalController = TextEditingController();
  
  List<Airport> _airports = [];
  List<Airplane> _airplanes = [];
  Airport? _selectedOrigin;
  Airport? _selectedDestination;
  Airplane? _selectedAirplane;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  FlightStatus _status = FlightStatus.SCHEDULED;
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _staffApi = StaffApi(_apiClient);
    _airportsApi = AirportsApi(_apiClient);
    _loadData();
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _basePriceController.dispose();
    _gateController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final airports = await _airportsApi.getAirports();
      final airplanes = await _staffApi.getAllAirplanes();
      
      setState(() {
        _airports = airports;
        _airplanes = airplanes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _selectDepartureDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _departureDate = date);
    }
  }

  Future<void> _selectDepartureTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _departureTime = time);
    }
  }

  Future<void> _selectArrivalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _arrivalDate ?? _departureDate ?? DateTime.now(),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date != null) {
      setState(() => _arrivalDate = date);
    }
  }

  Future<void> _selectArrivalTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _arrivalTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _arrivalTime = time);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOrigin == null || _selectedDestination == null || _selectedAirplane == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    if (_departureDate == null || _departureTime == null || _arrivalDate == null || _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure and arrival date/time')),
      );
      return;
    }

    final departureDateTime = _combineDateAndTime(_departureDate!, _departureTime!);
    final arrivalDateTime = _combineDateAndTime(_arrivalDate!, _arrivalTime!);

    if (arrivalDateTime.isBefore(departureDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival time must be after departure time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _staffApi.createFlight({
        'flight_number': _flightNumberController.text.trim(),
        'airplane_id': _selectedAirplane!.id,
        'origin_airport_id': _selectedOrigin!.id,
        'destination_airport_id': _selectedDestination!.id,
        'departure_time': departureDateTime.toIso8601String(),
        'arrival_time': arrivalDateTime.toIso8601String(),
        'base_price': double.parse(_basePriceController.text.trim()),
        'gate': _gateController.text.trim().isEmpty ? null : _gateController.text.trim(),
        'terminal': _terminalController.text.trim().isEmpty ? null : _terminalController.text.trim(),
        'status': _status.toJson(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight created successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create flight: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Flight')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Flight')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _flightNumberController,
              decoration: const InputDecoration(
                labelText: 'Flight Number',
                prefixIcon: Icon(Icons.flight),
                hintText: 'e.g., AA123',
              ),
              validator: (v) => Validators.validateRequired(v, 'Flight Number'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Airplane>(
              initialValue: _selectedAirplane,
              decoration: const InputDecoration(
                labelText: 'Airplane',
                prefixIcon: Icon(Icons.airplanemode_active),
              ),
              items: _airplanes.map((airplane) {
                return DropdownMenuItem(
                  value: airplane,
                  child: Text('${airplane.model} (${airplane.registration})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedAirplane = value),
              validator: (v) => v == null ? 'Please select an airplane' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Airport>(
              initialValue: _selectedOrigin,
              decoration: const InputDecoration(
                labelText: 'Origin Airport',
                prefixIcon: Icon(Icons.flight_takeoff),
              ),
              items: _airports.map((airport) {
                return DropdownMenuItem(
                  value: airport,
                  child: Text('${airport.code} - ${airport.name}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedOrigin = value),
              validator: (v) => v == null ? 'Please select origin airport' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Airport>(
              initialValue: _selectedDestination,
              decoration: const InputDecoration(
                labelText: 'Destination Airport',
                prefixIcon: Icon(Icons.flight_land),
              ),
              items: _airports.map((airport) {
                return DropdownMenuItem(
                  value: airport,
                  child: Text('${airport.code} - ${airport.name}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDestination = value),
              validator: (v) => v == null ? 'Please select destination airport' : null,
            ),
            const SizedBox(height: 24),
            const Text('Departure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_departureDate == null ? 'Select Date' : _departureDate!.toString().split(' ')[0]),
                    leading: const Icon(Icons.calendar_today),
                    onTap: _selectDepartureDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text(_departureTime == null ? 'Select Time' : _departureTime!.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: _selectDepartureTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Arrival', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_arrivalDate == null ? 'Select Date' : _arrivalDate!.toString().split(' ')[0]),
                    leading: const Icon(Icons.calendar_today),
                    onTap: _selectArrivalDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text(_arrivalTime == null ? 'Select Time' : _arrivalTime!.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: _selectArrivalTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _basePriceController,
              decoration: const InputDecoration(
                labelText: 'Base Price',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '100.00',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Base price is required';
                if (double.tryParse(v) == null) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gateController,
              decoration: const InputDecoration(
                labelText: 'Gate (Optional)',
                prefixIcon: Icon(Icons.door_front_door),
                hintText: 'e.g., A12',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _terminalController,
              decoration: const InputDecoration(
                labelText: 'Terminal (Optional)',
                prefixIcon: Icon(Icons.location_city),
                hintText: 'e.g., Terminal 1',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FlightStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info),
              ),
              items: FlightStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Create Flight',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
