import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/auth_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/passenger_profile.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';
import '../../app/router.dart';

class PassengerInfoPage extends StatefulWidget {
  final int flightId;

  const PassengerInfoPage({super.key, required this.flightId});

  @override
  State<PassengerInfoPage> createState() => _PassengerInfoPageState();
}

class _PassengerInfoPageState extends State<PassengerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  
  PassengerProfile? _profile;
  bool _isLoading = true;
  int _passengerCount = 1;
  final List<Map<String, TextEditingController>> _passengerControllers = [];

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _authApi = AuthApi(_apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authApi.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
        _initializePassengers();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _initializePassengers() {
    _passengerControllers.clear();
    for (int i = 0; i < _passengerCount; i++) {
      _passengerControllers.add({
        'name': TextEditingController(
          text: i == 0 && _profile != null ? _profile!.fullName : '',
        ),
        'passport': TextEditingController(
          text: i == 0 && _profile != null ? _profile!.passportNumber : '',
        ),
      });
    }
  }

  @override
  void dispose() {
    for (var controllers in _passengerControllers) {
      controllers['name']?.dispose();
      controllers['passport']?.dispose();
    }
    super.dispose();
  }

  void _addPassenger() {
    if (_passengerCount >= AppConstants.maxPassengersPerBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${AppConstants.maxPassengersPerBooking} passengers allowed')),
      );
      return;
    }

    setState(() {
      _passengerCount++;
      _passengerControllers.add({
        'name': TextEditingController(),
        'passport': TextEditingController(),
      });
    });
  }

  void _removePassenger(int index) {
    if (_passengerCount <= 1) return;

    setState(() {
      _passengerControllers[index]['name']?.dispose();
      _passengerControllers[index]['passport']?.dispose();
      _passengerControllers.removeAt(index);
      _passengerCount--;
    });
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    if (_profile == null || !_profile!.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile before booking'),
        ),
      );
      Navigator.of(context).pushNamed(AppRouter.profileEdit);
      return;
    }

    final passengers = _passengerControllers.map((controllers) {
      return {
        'full_name': controllers['name']!.text.trim(),
        'passport_number': controllers['passport']!.text.trim(),
      };
    }).toList();

    Navigator.of(context).pushNamed(
      AppRouter.seatSelection,
      arguments: {
        'flightId': widget.flightId,
        'passengers': passengers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passenger Information')),
        body: const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Information'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Passengers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to ${AppConstants.maxPassengersPerBooking} passengers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildPassengerForms(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addPassenger,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Passenger'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Continue to Seat Selection',
              onPressed: _continue,
              icon: Icons.event_seat,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPassengerForms() {
    return _passengerControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controllers = entry.value;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Passenger ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (index == 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (index > 0)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removePassenger(index),
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['name'],
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['passport'],
                decoration: const InputDecoration(
                  labelText: 'Passport Number',
                  prefixIcon: Icon(Icons.card_travel),
                ),
                validator: Validators.validatePassportNumber,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
