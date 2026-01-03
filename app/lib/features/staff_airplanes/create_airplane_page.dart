import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';

class CreateAirplanePage extends StatefulWidget {
  const CreateAirplanePage({super.key});

  @override
  State<CreateAirplanePage> createState() => _CreateAirplanePageState();
}

class _CreateAirplanePageState extends State<CreateAirplanePage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _capacityController = TextEditingController();
  
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
  }

  @override
  void dispose() {
    _modelController.dispose();
    _manufacturerController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _staffApi.createAirplane({
        'model': _modelController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'total_seats': int.parse(_capacityController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airplane created successfully')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Airplane')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Manufacturer',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => Validators.validateRequired(v, 'Manufacturer'),
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
              text: 'Create Airplane',
              onPressed: _submit,
              isLoading: _isSubmitting,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
