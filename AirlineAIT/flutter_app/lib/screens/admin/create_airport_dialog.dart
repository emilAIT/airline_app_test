import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class CreateAirportDialog extends StatefulWidget {
  const CreateAirportDialog({super.key});

  @override
  State<CreateAirportDialog> createState() => _CreateAirportDialogState();
}

class _CreateAirportDialogState extends State<CreateAirportDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  Future<void> _createAirport() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final formData = _formKey.currentState!.value;
        
        final airportData = {
          'code': formData['code'],
          'name': formData['name'],
          'city': formData['city'],
          'country': formData['country'],
        };

        // Note: The backend route is createAirport but in ApiService it might need to be added or verified.
        // I checked api_service.dart earlier and it has getAirports but I didn't verify createAirport method.
        // Wait, I strictly didn't see create_airport in the viewed file `api_service.dart` in previous turns?
        // Let me check my memory of api_service.dart.
        // I looked at it in Step 181. 
        // It has getAirports line 88. 
        // It DOES NOT have createAirport.
        // I need to add createAirport to ApiService first! 
        // But I can't interrupt this write_to_file.
        // I will assume I will add it in the next step.
        // Actually, I should probably handle this by adding the method to ApiService immediately after this.
        
        // I will write the code assuming the method exists, then add it.
        // But `ApiService` is not a mixin so I can't just call it if it's not there.
        // I will implement it here, but I must remember to update ApiService.
        
        // Assuming I add `createAirport(Map<String, dynamic> data)` to ApiService.
        // But wait, the previous `api_service.dart` view showed `createStaffFlight` etc. but not `createAirport`.
        // The backend admin routes has `create_airport`.
        
        // Let's assume I'll name it createAirport.
        await apiService.createAirport(airportData);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Airport created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create airport: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Airport'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'code',
                  decoration: const InputDecoration(
                    labelText: 'Airport Code (IATA)',
                    border: OutlineInputBorder(),
                    helperText: 'e.g., DXB, LHR, JFK',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length != 3) return 'Must be 3 letters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'name',
                  decoration: const InputDecoration(
                    labelText: 'Airport Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'city',
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'country',
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAirport,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
