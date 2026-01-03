import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class CreateAnnouncementDialog extends StatefulWidget {
  const CreateAnnouncementDialog({super.key});

  @override
  State<CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<CreateAnnouncementDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<dynamic> _flights = [];
  bool _isLoading = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getStaffFlights();
      
      if (mounted) {
        setState(() {
          _flights = List<dynamic>.from(response.data ?? []);
          _loadingData = false;
        });
        
        // Add General option if we have flights or even if we don't? Always allow General.
        // We will insert it in the build method or here.
        // Actually, if _flights is empty, the current code shows "No flights found" snackbar.
        // We want to handle that.
        
        if (_flights.isEmpty) {
          // No flights, but that's okay for general announcements
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load flights: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final formData = _formKey.currentState!.value;
        
        final announcementData = {
          'flight_id': formData['flight_id'],
          'title': formData['title'],
          'message': formData['message'],
          'type': formData['type'] ?? 'GENERAL',
        };

        await apiService.createStaffAnnouncement(announcementData);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create announcement: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Announcement'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingData
            ? const LoadingWidget()
            : SingleChildScrollView(
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormBuilderDropdown<int?>(
                        name: 'flight_id',
                        decoration: const InputDecoration(
                          labelText: 'Flight (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight),
                        ),
                        // Always allow selecting None for General
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('General Announcement (All Users)'),
                          ),
                          ..._flights.map((flight) {
                            return DropdownMenuItem<int?>(
                              value: flight['id'],
                              child: Text(
                                '${flight['flight_number'] ?? 'N/A'} - ${flight['origin_airport']?['code'] ?? 'N/A'} → ${flight['destination_airport']?['code'] ?? 'N/A'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        validator: (value) => null, // Optional now
                      ),
                      if (_flights.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No specific flights found, but you can create a General Announcement.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'title',
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.length > 100) {
                            return 'Title must be 100 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'message',
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          if (value.length > 500) {
                            return 'Message must be 500 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'type',
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        initialValue: 'GENERAL',
                        items: const [
                          DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                          DropdownMenuItem(value: 'DELAY', child: Text('Delay')),
                          DropdownMenuItem(value: 'CANCELLATION', child: Text('Cancellation')),
                          DropdownMenuItem(value: 'GATE_CHANGE', child: Text('Gate Change')),
                          DropdownMenuItem(value: 'BOARDING_STARTED', child: Text('Boarding Started')),
                        ],
                        validator: (value) => value == null ? 'Please select a type' : null,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAnnouncement,
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

