import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/flight.dart';
import '../../shared/models/enums.dart';
import '../../shared/utils/constants.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';

class EditFlightPage extends StatefulWidget {
  final int flightId;

  const EditFlightPage({
    super.key,
    required this.flightId,
  });

  @override
  State<EditFlightPage> createState() => _EditFlightPageState();
}

class _EditFlightPageState extends State<EditFlightPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  
  final _gateController = TextEditingController();
  final _terminalController = TextEditingController();
  
  Flight? _flight;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  FlightStatus? _status;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _staffApi = StaffApi(_apiClient);
    _loadFlight();
  }

  @override
  void dispose() {
    _gateController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _loadFlight() async {
    setState(() => _isLoading = true);

    try {
      final flight = await _staffApi.getFlightById(widget.flightId);
      
      setState(() {
        _flight = flight;
        _departureDate = flight.departureTime;
        _departureTime = TimeOfDay.fromDateTime(flight.departureTime);
        _arrivalDate = flight.arrivalTime;
        _arrivalTime = TimeOfDay.fromDateTime(flight.arrivalTime);
        _status = flight.status;
        _gateController.text = flight.gate ?? '';
        _terminalController.text = flight.terminal ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      await _staffApi.updateFlight(widget.flightId, {
        'departure_time': departureDateTime.toIso8601String(),
        'arrival_time': arrivalDateTime.toIso8601String(),
        'gate': _gateController.text.trim().isEmpty ? null : _gateController.text.trim(),
        'terminal': _terminalController.text.trim().isEmpty ? null : _terminalController.text.trim(),
        'status': _status!.toJson(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update flight: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Flight')),
        body: const LoadingView(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Flight')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFlight,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flight == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Flight')),
        body: const Center(child: Text('Flight not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Edit Flight ${_flight!.flightNumber}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flight ${_flight!.flightNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  Text('${_flight!.origin?.code ?? "N/A"} → ${_flight!.destination?.code ?? "N/A"}'),
                  Text('Airplane: ${_flight!.airplane?.model ?? "N/A"}'),
                  ],
                ),
              ),
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
              controller: _gateController,
              decoration: const InputDecoration(
                labelText: 'Gate',
                prefixIcon: Icon(Icons.door_front_door),
                hintText: 'e.g., A12',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _terminalController,
              decoration: const InputDecoration(
                labelText: 'Terminal',
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
              text: 'Update Flight',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
