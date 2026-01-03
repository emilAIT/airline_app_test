import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:airline_app/presentation/cubits/auth_cubit.dart';
import 'package:airline_app/data/models/profile_model.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passportController = TextEditingController();
  final _nationalityController = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is Authenticated && state.profile != null) {
      _firstNameController.text = state.profile!.firstName;
      _lastNameController.text = state.profile!.lastName;
      _passportController.text = state.profile!.passportNumber;
      _nationalityController.text = state.profile!.nationality;
      _dob = state.profile!.dateOfBirth;
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate() && _dob != null) {
      final state = context.read<AuthCubit>().state;
      if (state is Authenticated) {
        final profile = ProfileModel(
          id: state.profile?.id ?? 0,
          userId: state.user.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          passportNumber: _passportController.text,
          dateOfBirth: _dob!,
          nationality: _nationalityController.text,
        );
        context.read<AuthCubit>().updateProfile(profile);
      }
    } else if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated && state.isProfileComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile completed successfully!')),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Almost there!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please complete your passenger profile to start booking flights.'),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passportController,
                    decoration: const InputDecoration(
                      labelText: 'Passport Number',
                      prefixIcon: Icon(Icons.assignment_ind_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your passport number' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(_dob == null ? '' : DateFormat('yyyy-MM-dd').format(_dob!)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(
                      labelText: 'Nationality',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your nationality' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: state is AuthLoading ? null : _onSave,
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE & CONTINUE'),
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
