import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/staff_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/airplane.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/empty_view.dart';
import '../../shared/utils/constants.dart';
import '../../app/router.dart';

class StaffAirplanesPage extends StatefulWidget {
  const StaffAirplanesPage({super.key});

  @override
  State<StaffAirplanesPage> createState() => _StaffAirplanesPageState();
}

class _StaffAirplanesPageState extends State<StaffAirplanesPage> {
  late final ApiClient _apiClient;
  late final StaffApi _staffApi;
  List<Airplane> _airplanes = [];
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
    _staffApi = StaffApi(_apiClient);
    _loadAirplanes();
  }

  Future<void> _loadAirplanes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final airplanes = await _staffApi.getAirplanes();
      setState(() {
        _airplanes = airplanes;
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
      appBar: AppBar(title: const Text('Manage Airplanes')),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadAirplanes)
              : _airplanes.isEmpty
                  ? const EmptyView(message: 'No airplanes found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _airplanes.length,
                      itemBuilder: (context, index) {
                        final airplane = _airplanes[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.flight),
                            ),
                            title: Text(airplane.model),
                            subtitle: Text('Capacity: ${airplane.totalSeats} seats'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRouter.staffAirplaneDetails,
                                  arguments: airplane.id,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.staffAirplaneCreate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
