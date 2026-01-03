import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final List<dynamic> flights;

  const CreateAnnouncementScreen({
    super.key,
    required this.flights,
  });

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String? _selectedType;
  int? _selectedFlightId;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select announcement type'),
          backgroundColor: EldiyarTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _api.createAnnouncement({
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'flight_id': _selectedFlightId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement created successfully!'),
            backgroundColor: EldiyarTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating announcement: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
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
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: EldiyarTheme.primaryBlue,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Announcement',
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
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Announcement Type *',
                              prefixIcon: Icon(
                                Icons.category,
                                color: EldiyarTheme.primaryBlue,
                              ),
                            ),
                            style: const TextStyle(
                              color: EldiyarTheme.textPrimary,
                            ),
                            dropdownColor: EldiyarTheme.cardBackground,
                            items: const [
                              'DELAY',
                              'CANCELLATION',
                              'GATE_CHANGE',
                              'BOARDING_STARTED',
                              'GENERAL',
                            ].map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedFlightId,
                            decoration: const InputDecoration(
                              labelText: 'Flight (optional)',
                              prefixIcon: Icon(
                                Icons.flight,
                                color: EldiyarTheme.primaryBlue,
                              ),
                            ),
                            style: const TextStyle(
                              color: EldiyarTheme.textPrimary,
                            ),
                            dropdownColor: EldiyarTheme.cardBackground,
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text(
                                  'General Announcement',
                                  style: TextStyle(
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                ),
                              ),
                              ...widget.flights.map((flight) {
                                return DropdownMenuItem<int>(
                                  value: flight['id'],
                                  child: Text(
                                    '${flight['flight_number']} - ${flight['origin']['code']} → ${flight['destination']['code']}',
                                    style: const TextStyle(
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedFlightId = value),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: EldiyarTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              prefixIcon: Icon(
                                Icons.title,
                                color: EldiyarTheme.primaryBlue,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _messageController,
                            style: const TextStyle(
                              color: EldiyarTheme.textPrimary,
                            ),
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Message *',
                              prefixIcon: Icon(
                                Icons.message,
                                color: EldiyarTheme.primaryBlue,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter message';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          GlowButton(
                            label: 'Create Announcement',
                            icon: Icons.add,
                            onPressed: _isCreating ? null : _createAnnouncement,
                            isLoading: _isCreating,
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

