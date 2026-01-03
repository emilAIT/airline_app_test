import 'package:flutter/material.dart';
import 'package:ait_airlines/core/di/injection.dart';
import 'package:ait_airlines/features/admin/domain/repositories/admin_repository.dart';
import 'package:ait_airlines/features/admin/domain/entities/admin_user_summary.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminRepository _repo = getIt<AdminRepository>();
  bool _loading = true;
  List<AdminUserSummary> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.getUsersSummary();
    res.fold(
      (fail) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${fail.toString()}')),
      ),
      (list) => _items = list,
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final staff = _items.where((u) => u.role == 'staff').toList();
    final users = _items.where((u) => u.role != 'staff').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи и стафф'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('STAFF', staff, Colors.orange),
                  const SizedBox(height: 16),
                  _section('USERS', users, Colors.blue),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<AdminUserSummary> data, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  backgroundColor: color.withOpacity(0.1),
                  label: Text('Всего: ${data.length}', style: TextStyle(color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Нет записей'),
              ),
            ...data.map(_userTile).toList(),
          ],
        ),
      ),
    );
  }

  Widget _userTile(AdminUserSummary u) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${u.firstName ?? ''} ${u.lastName ?? ''}'.trim(), style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Chip(
                label: Text(u.status),
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _linkedRow('Flights', u.flights),
          const SizedBox(height: 6),
          _linkedRow('Airplanes', u.airplanes),
        ],
      ),
    );
  }

  Widget _linkedRow(String label, List<LinkedItem> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items.isEmpty
                ? [const Text('—')]
                : items.map((i) => Chip(label: Text(i.label), backgroundColor: Colors.blue.shade50)).toList(),
          ),
        ),
      ],
    );
  }
}

