import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';


class EditAirplanePage extends StatefulWidget {
  final int airplaneId;

  const EditAirplanePage({super.key, required this.airplaneId});

  @override
  State<EditAirplanePage> createState() => _EditAirplanePageState();
}

class _EditAirplanePageState extends State<EditAirplanePage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _capacityController = TextEditingController();
  
  bool _isLoading = true;
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
    _loadAirplane();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _registrationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadAirplane() async {
    try {
      final airplane = await _staffApi.getAirplane(widget.airplaneId);
      if (mounted) {
        setState(() {
          _modelController.text = airplane.model;
          _registrationController.text = airplane.registration;
          _capacityController.text = airplane.totalSeats.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _staffApi.updateAirplane(widget.airplaneId, {
        'model': _modelController.text.trim(),
        'registration': _registrationController.text.trim(),
        'total_seats': int.parse(_capacityController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airplane updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView());
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _loadAirplane));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Airplane')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _registrationController,
              decoration: const InputDecoration(
                labelText: 'Registration (e.g. TC-JRO)',
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (v) => Validators.validateRequired(v, 'Registration'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.flight),
              ),
              validator: (v) => Validators.validateRequired(v, 'Model'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                prefixIcon: Icon(Icons.event_seat),
                helperText: 'Changing capacity will reset seating layout. Cannot change if flights exist.',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Capacity is required';
                if (int.tryParse(v) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save Changes',
              onPressed: _submit,
              isLoading: _isSubmitting,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
