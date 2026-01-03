import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final AdminRepository _repository = getIt<AdminRepository>();
  List<User> _pendingStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingStaff();
  }

  Future<void> _loadPendingStaff() async {
    setState(() => _isLoading = true);
    final result = await _repository.getPendingStaff();
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${failure.toString()}')),
      ),
      (staff) => setState(() => _pendingStaff = staff),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _approve(int id) async {
    final result = await _repository.approveStaff(id);
    result.fold(
      (failure) => null,
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff approved!')));
        _loadPendingStaff();
      },
    );
  }

  Future<void> _reject(int id) async {
    final result = await _repository.rejectStaff(id);
    result.fold(
      (failure) => null,
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff rejected!')));
        _loadPendingStaff();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Approvals'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _pendingStaff.isEmpty
          ? const Center(child: Text('No pending staff requests'))
          : ListView.builder(
              itemCount: _pendingStaff.length,
              itemBuilder: (context, index) {
                final staff = _pendingStaff[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(staff.email),
                    subtitle: Text('ID: ${staff.id} | Joined: ${staff.createdAt?.toString().split(' ')[0] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _approve(staff.id!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _reject(staff.id!),
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
