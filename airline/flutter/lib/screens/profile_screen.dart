import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _passportController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  DateTime? _dateOfBirth;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _passportController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _api.getProfile();
      setState(() {
        _profile = profile;
        _passportController.text = profile['passport_number'] ?? '';
        _phoneController.text = profile['phone_number'] ?? '';
        _nationalityController.text = profile['nationality'] ?? '';
        if (profile['date_of_birth'] != null) {
          _dateOfBirth = DateTime.parse(profile['date_of_birth']);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Profile might not exist yet - that's okay
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EldiyarTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: EldiyarTheme.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date of birth'),
          backgroundColor: EldiyarTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profileData = {
        'passport_number': _passportController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'nationality': _nationalityController.text.trim(),
        'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
      };

      if (_profile == null) {
        await _api.createProfile(profileData);
      } else {
        await _api.updateProfile(profileData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: EldiyarTheme.successGreen,
          ),
        );
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
                    const Expanded(
                      child: Text(
                        'Passenger Profile',
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
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: EldiyarTheme.primaryBlue
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: EldiyarTheme.primaryBlue
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: EldiyarTheme.primaryBlue,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Complete Your Profile',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: EldiyarTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Required to book flights',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: EldiyarTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _passportController,
                                  style: const TextStyle(
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Passport Number *',
                                    prefixIcon: Icon(
                                      Icons.credit_card,
                                      color: EldiyarTheme.primaryBlue,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter passport number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  style: const TextStyle(
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number *',
                                    prefixIcon: Icon(
                                      Icons.phone,
                                      color: EldiyarTheme.primaryBlue,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nationalityController,
                                  style: const TextStyle(
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Nationality *',
                                    prefixIcon: Icon(
                                      Icons.flag,
                                      color: EldiyarTheme.primaryBlue,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter nationality';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: _selectDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Date of Birth *',
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        color: EldiyarTheme.primaryBlue,
                                      ),
                                    ),
                                    child: Text(
                                      _dateOfBirth == null
                                          ? 'Select date of birth'
                                          : DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(_dateOfBirth!),
                                      style: const TextStyle(
                                        color: EldiyarTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GlowButton(
                                  label: 'Save Profile',
                                  icon: Icons.save,
                                  onPressed: _isSaving ? null : _saveProfile,
                                  isLoading: _isSaving,
                                ),
                              ],
                            ),
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
