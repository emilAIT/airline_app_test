import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/core/api_client.dart';
import 'package:airline_app/data/repositories/staff_repository.dart';
import 'package:airline_app/presentation/cubits/staff_cubit.dart';

class StaffAirplaneScreen extends StatefulWidget {
  const StaffAirplaneScreen({super.key});

  @override
  State<StaffAirplaneScreen> createState() => _StaffAirplaneScreenState();
}

class _StaffAirplaneScreenState extends State<StaffAirplaneScreen> {
  late Future<List<dynamic>> _airplanesFuture;

  @override
  void initState() {
    super.initState();
    _loadAirplanes();
  }

  void _loadAirplanes() {
    setState(() {
      _airplanesFuture = context.read<StaffRepository>().getAllAirplanes().then(
        (airplanes) => airplanes.map((a) => {
          'id': a.id,
          'model': a.model,
          'registrationNumber': a.registrationNumber,
          'totalSeats': a.totalSeats,
          'seatTemplate': a.seatTemplate,
        }).toList()
      );
    });
  }

  Future<void> _deleteAirplane(int airplaneId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.delete('/staff/airplanes/$airplaneId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Airplane deleted successfully')),
      );
      _loadAirplanes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCreateDialog() {
    final modelController = TextEditingController();
    final regNumberController = TextEditingController();
    final rowsController = TextEditingController(text: '30');
    final seatsPerRowController = TextEditingController(text: '6');
    String selectedLayout = 'A-B-C_D-E-F'; // Default 3-3 configuration

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Airplane'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model (e.g., Boeing 737)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Rows',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: seatsPerRowController,
                  decoration: const InputDecoration(
                    labelText: 'Seats per Row',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLayout,
                  decoration: const InputDecoration(
                    labelText: 'Seat Layout Configuration',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A-B-C_D-E-F', child: Text('3-3 (A-B-C | D-E-F)')),
                    DropdownMenuItem(value: 'A-B-C', child: Text('3-0 (A-B-C)')),
                    DropdownMenuItem(value: 'A-B_C-D', child: Text('2-2 (A-B | C-D)')),
                    DropdownMenuItem(value: 'A-B_D-E-F', child: Text('2-3 (A-B | D-E-F)')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedLayout = value!),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total seats: ${int.tryParse(rowsController.text) ?? 0} × ${int.tryParse(seatsPerRowController.text) ?? 0} = ${(int.tryParse(rowsController.text) ?? 0) * (int.tryParse(seatsPerRowController.text) ?? 0)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (modelController.text.isEmpty || regNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                final rows = int.tryParse(rowsController.text) ?? 30;
                final seatsPerRow = int.tryParse(seatsPerRowController.text) ?? 6;
                
                try {
                  final apiClient = ApiClient();
                  await apiClient.post('/staff/airplanes', body: {
                    'model': modelController.text,
                    'registration_number': regNumberController.text,
                    'total_seats': rows * seatsPerRow,
                    'seat_template': {
                      'rows': rows,
                      'seats_per_row': seatsPerRow,
                      'layout': selectedLayout,
                    },
                  });
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Airplane created successfully')),
                  );
                  _loadAirplanes();
                  context.read<StaffCubit>().loadDashboardData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAirplaneDetails(Map<String, dynamic> airplane) {
    final seatTemplate = airplane['seatTemplate'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(airplane['model']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Registration', airplane['registrationNumber']),
              _DetailRow('Total Seats', '${airplane['totalSeats']}'),
              _DetailRow('Rows', '${seatTemplate['rows'] ?? 'N/A'}'),
              _DetailRow('Seats per Row', '${seatTemplate['seats_per_row'] ?? 'N/A'}'),
              _DetailRow('Layout', seatTemplate['layout'] ?? 'Standard'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(airplane);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMapPreview(Map<String, dynamic> seatTemplate) {
    final rows = seatTemplate['rows'] ?? 30;
    final seatsPerRow = seatTemplate['seats_per_row'] ?? 6;
    final layout = seatTemplate['layout'] ?? 'A-B-C_D-E-F';
    final letters = layout.replaceAll('_', '').replaceAll('-', '');
    
    // Generate seat labels based on seatsPerRow
    final seatLabels = List.generate(seatsPerRow, (index) {
      if (index < letters.length) {
        return letters[index];
      }
      return String.fromCharCode(65 + index); // A, B, C, etc.
    });
    
    // Show only first 5 rows as preview
    final previewRows = rows > 5 ? 5 : rows;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ...List.generate(previewRows, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${rowIndex + 1}', style: const TextStyle(fontSize: 10)),
                  ),
                  ...List.generate(seatsPerRow, (seatIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Center(
                          child: Text(
                            seatLabels[seatIndex],
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          if (rows > 5) const Text('... and more rows', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> airplane) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Airplane'),
        content: Text('Are you sure you want to delete ${airplane['model']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAirplane(airplane['id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _airplanesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final airplanes = snapshot.data ?? [];

          if (airplanes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No airplanes yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Airplane'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: airplanes.length,
            itemBuilder: (context, index) {
              final airplane = airplanes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF673AB7),
                    child: Icon(Icons.flight, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    airplane['model'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Reg: ${airplane['registrationNumber']} | ${airplane['totalSeats']} seats',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAirplaneDetails(airplane),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
