// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import 'add_aircraft_screen.dart';

class StaffAirplanesScreen extends StatefulWidget {
  const StaffAirplanesScreen({super.key});

  @override
  State<StaffAirplanesScreen> createState() => _StaffAirplanesScreenState();
}

class _StaffAirplanesScreenState extends State<StaffAirplanesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _airplanes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.staffListAirplanes();
      final items = <Map<String, dynamic>>[];
      for (final a in raw) {
        if (a is Map) items.add(a.cast<String, dynamic>());
      }

      if (!mounted) return;
      setState(() {
        _airplanes = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _editAirplane(Map<String, dynamic> airplane) async {
    final idRaw = airplane['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) return;

    final modelController = TextEditingController(
      text: (airplane['model'] ?? '').toString(),
    );
    final manufacturerController = TextEditingController(
      text: (airplane['manufacturer'] ?? '').toString(),
    );
    final seatsController = TextEditingController(
      text: (airplane['total_seats'] ?? '').toString(),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Редактирование самолёта',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Модель'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: manufacturerController,
                decoration: const InputDecoration(labelText: 'Производитель'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Всего мест'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена', style: GoogleFonts.montserrat()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ZaKuColors.gold,
                foregroundColor: ZaKuColors.burgundy,
              ),
              child: Text(
                'Сохранить',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final seats = int.tryParse(seatsController.text.trim());

    try {
      await ApiService.staffUpdateAirplane(
        id,
        model: modelController.text.trim(),
        manufacturer: manufacturerController.text.trim(),
        totalSeats: seats,
      );
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Самолёт обновлён')));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Ошибка обновления' : msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Управление самолетами',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Aircraft',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAircraftScreen()),
              );
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: GoogleFonts.montserrat(color: Colors.red),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _airplanes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = _airplanes[index];
                        final reg = a['registration_number']?.toString() ?? '';
                        final model = a['model']?.toString() ?? '';
                        final manufacturer =
                            a['manufacturer']?.toString() ?? '';
                        final seats = a['total_seats']?.toString() ?? '';

                        final title = reg.isNotEmpty ? reg : 'Самолёт';
                        final subtitle = [
                          if (model.isNotEmpty) model,
                          if (manufacturer.isNotEmpty) manufacturer,
                        ].join(' • ');

                        return InkWell(
                          onTap: () => _editAirplane(a),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ZaKuColors.gold.withOpacity(0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle.isEmpty ? '—' : subtitle,
                                  style: GoogleFonts.montserrat(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Мест: ${seats.isEmpty ? '—' : seats}',
                                  style: GoogleFonts.montserrat(
                                    color: ZaKuColors.darkGrey.withOpacity(
                                      0.75,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Нажмите для редактирования',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: ZaKuColors.darkGrey.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )),
    );
  }
}
