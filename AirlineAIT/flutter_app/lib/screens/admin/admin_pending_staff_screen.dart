import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class AdminPendingStaffScreen extends StatefulWidget {
  const AdminPendingStaffScreen({super.key});

  @override
  State<AdminPendingStaffScreen> createState() => _AdminPendingStaffScreenState();
}

class _AdminPendingStaffScreenState extends State<AdminPendingStaffScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingStaff = [];

  @override
  void initState() {
    super.initState();
    _loadPendingStaff();
  }

  Future<void> _loadPendingStaff() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final staff = await apiService.getPendingStaff();
      setState(() {
        _pendingStaff = staff;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pending staff: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveStaff(int userId) async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.approveStaff(userId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff approved successfully')),
          );
        }
        _loadPendingStaff();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to approve staff')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectStaff(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Staff Request'),
        content: const Text('Are you sure you want to reject this registration? The account will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.rejectStaff(userId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff request rejected')),
          );
        }
        _loadPendingStaff();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to reject staff')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_pendingStaff.isEmpty) {
      return const Center(
        child: Text('No pending staff registrations'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStaff.length,
      itemBuilder: (context, index) {
        final staff = _pendingStaff[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(staff['email'] ?? 'Unknown Email'),
            subtitle: const Text('Status: Pending Approval'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Approve',
                  onPressed: () => _approveStaff(staff['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Reject',
                  onPressed: () => _rejectStaff(staff['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
