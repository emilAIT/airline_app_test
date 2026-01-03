import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() =>
      _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  final fullNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passportCtrl = TextEditingController();
  final nationalityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? dateOfBirth;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    final profile =
        context.read<AuthProvider>().user?.profile;

    if (profile != null) {
      fullNameCtrl.text = profile.fullName ?? '';
      phoneCtrl.text = profile.phone ?? '';
      passportCtrl.text = profile.passportNumber ?? '';
      nationalityCtrl.text = profile.nationality ?? '';
      dateOfBirth = profile.dateOfBirth;
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => dateOfBirth = picked);
    }
  }

  String? get dateString {
    if (dateOfBirth == null) return null;
    return dateOfBirth!.toIso8601String().split('T').first;
  }

  Future<void> save() async {
    setState(() => loading = true);

    await ApiClient.put('/me/profile_update', {
      'full_name': fullNameCtrl.text,
      'phone': phoneCtrl.text,
      'passport_number': passportCtrl.text,
      'nationality': nationalityCtrl.text,
      'date_of_birth': dateString,
    });

    setState(() => loading = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: passportCtrl,
                decoration:
                    const InputDecoration(labelText: 'Passport number'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nationalityCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nationality'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller:
                        TextEditingController(text: dateString ?? ''),
                    validator: (_) =>
                        dateOfBirth == null ? 'Required field' : null,
                  ),
                ),
              ),

              const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            save();
                          }
                        },
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }