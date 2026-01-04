import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_event.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/core/di/injection.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _currentProfile;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passportNumberController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_isInitialized) return;
    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.dio.get('/users/me/profile');
      if (response.statusCode == 200) {
        _currentProfile = response.data;
        _firstNameController.text = _currentProfile!['first_name'] ?? '';
        _lastNameController.text = _currentProfile!['last_name'] ?? '';
        _phoneController.text = _currentProfile!['phone'] ?? '';
        _passportNumberController.text = _currentProfile!['passport_number'] ?? '';
        _nationalityController.text = _currentProfile!['nationality'] ?? '';
        _isInitialized = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.dio.put(
        '/users/me/profile',
        data: {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'passport_number': _passportNumberController.text.isNotEmpty ? _passportNumberController.text : null,
          'nationality': _nationalityController.text.isNotEmpty ? _nationalityController.text : null,
        },
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh auth state
          context.read<AuthBloc>().add(AuthCheckRequested());
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: FutureBuilder(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (_isLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+77771234567',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passportNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Passport ID',
                      hintText: 'N1234567',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(
                      labelText: 'Nationality',
                      hintText: 'Kazakhstan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

