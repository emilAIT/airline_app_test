import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/auth_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/loading_view.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _nationalityController = TextEditingController();
  
  DateTime? _dateOfBirth;
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
    _authApi = AuthApi(_apiClient);
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _authApi.getProfile();
      setState(() {
        _fullNameController.text = profile.fullName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        _passportController.text = profile.passportNumber ?? '';
        _nationalityController.text = profile.nationality ?? '';
        _dateOfBirth = profile.dateOfBirth;
        _isLoading = false;
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

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authApi.updateProfile({
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'passport_number': _passportController.text.trim(),
        'nationality': _nationalityController.text.trim(),
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Complete your profile to book flights',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: Validators.validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passportController,
              decoration: const InputDecoration(
                labelText: 'Passport Number',
                prefixIcon: Icon(Icons.card_travel),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: Validators.validatePassportNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                prefixIcon: Icon(Icons.flag),
              ),
              textCapitalization: TextCapitalization.words,
              validator: Validators.validateNationality,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save Profile',
              onPressed: _saveProfile,
              isLoading: _isSubmitting,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}

