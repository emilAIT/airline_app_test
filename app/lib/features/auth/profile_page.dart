import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/auth_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/passenger_profile.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../app/router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  PassengerProfile? _profile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _authApi = AuthApi(_apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _authApi.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRouter.profileEdit,
              );
              if (result == true) {
                _loadProfile();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadProfile)
              : _profile == null
                  ? const Center(child: Text('No profile data'))
                  : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final profile = _profile!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!profile.isComplete)
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your profile to book flights',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Full Name', profile.fullName ?? 'Not set'),
                  _buildInfoRow('Phone', profile.phoneNumber ?? 'Not set'),
                  _buildInfoRow(
                    'Passport Number',
                    profile.passportNumber ?? 'Not set',
                  ),
                  _buildInfoRow('Nationality', profile.nationality ?? 'Not set'),
                  _buildInfoRow(
                    'Date of Birth',
                    profile.dateOfBirth != null
                        ? Formatters.formatDate(profile.dateOfBirth!)
                        : 'Not set',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        profile.isComplete
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color:
                            profile.isComplete ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        profile.isComplete
                            ? 'Profile Complete'
                            : 'Profile Incomplete',
                        style: TextStyle(
                          color:
                              profile.isComplete ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

