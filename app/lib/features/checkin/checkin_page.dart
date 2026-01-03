import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/checkin_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class CheckinPage extends StatefulWidget {
  final int ticketId;

  const CheckinPage({super.key, required this.ticketId});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  late final ApiClient _apiClient;
  late final CheckinApi _checkinApi;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _checkinApi = CheckinApi(_apiClient);
  }

  Future<void> _checkIn() async {
    setState(() => _isProcessing = true);

    try {
      await _checkinApi.checkIn(widget.ticketId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in successful!')),
        );
        Navigator.of(context).pushReplacementNamed(
          AppRouter.boardingPass,
          arguments: widget.ticketId,
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Check-in?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Check-in is available from 24 hours to 1 hour before departure.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Check-in Now',
              onPressed: _checkIn,
              isLoading: _isProcessing,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
}
