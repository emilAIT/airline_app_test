import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/primary_button.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _flightIdController = TextEditingController();
  
  AnnouncementType _type = AnnouncementType.GENERAL;
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
    _titleController.dispose();
    _messageController.dispose();
    _flightIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _staffApi.createAnnouncement({
        'flight_id': int.parse(_flightIdController.text.trim()),
        'type': _type.name,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created')),
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
      appBar: AppBar(title: const Text('Create Announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _flightIdController,
              decoration: const InputDecoration(
                labelText: 'Flight ID',
                prefixIcon: Icon(Icons.flight),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Flight ID required';
                if (int.tryParse(v) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AnnouncementType>(
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category),
              ),
              initialValue: _type,
              items: AnnouncementType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => Validators.validateRequired(v, 'Title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 4,
              validator: (v) => Validators.validateRequired(v, 'Message'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Create Announcement',
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
