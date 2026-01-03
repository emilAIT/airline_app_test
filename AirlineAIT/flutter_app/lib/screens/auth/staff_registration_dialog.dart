import 'package:flutter/material.dart';
import '../../widgets/loading_widget.dart';

class StaffRegistrationDialog extends StatefulWidget {
  final String email;
  final String password;

  const StaffRegistrationDialog({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<StaffRegistrationDialog> createState() => _StaffRegistrationDialogState();
}

class _StaffRegistrationDialogState extends State<StaffRegistrationDialog> {
  final List<dynamic> _airplanes = [];
  int? _selectedAirplaneId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAirplanes();
  }

  Future<void> _loadAirplanes() async {
    try {
      // Note: This endpoint requires authentication, so we'll need a public endpoint
      // For now, we'll show a message that admin needs to assign airplane
      setState(() {
        _isLoading = false;
        _errorMessage = 'Staff registration requires admin approval. Please contact admin to assign you to an airplane.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load airplanes. Please contact admin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register as Staff'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const LoadingWidget()
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select the airplane you will be assigned to:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_airplanes.isEmpty)
                        const Text('No airplanes available. Please contact admin.')
                      else
                        DropdownButtonFormField<int>(
                          initialValue: _selectedAirplaneId,
                          decoration: const InputDecoration(
                            labelText: 'Airplane',
                            border: OutlineInputBorder(),
                          ),
                          items: _airplanes.map((airplane) {
                            return DropdownMenuItem<int>(
                              value: airplane['id'],
                              child: Text('${airplane['model']} (${airplane['registration_number']})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAirplaneId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an airplane';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_errorMessage == null && _airplanes.isNotEmpty)
          ElevatedButton(
            onPressed: _selectedAirplaneId != null
                ? () => Navigator.of(context).pop(_selectedAirplaneId)
                : null,
            child: const Text('Register'),
          ),
      ],
    );
  }
}

