// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';

class StaffAnnouncementsScreen extends StatefulWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  State<StaffAnnouncementsScreen> createState() =>
      _StaffAnnouncementsScreenState();
}

class _StaffAnnouncementsScreenState extends State<StaffAnnouncementsScreen> {
  bool _loadingFlights = true;
  bool _loadingAnnouncements = false;
  String? _error;

  List<Map<String, dynamic>> _flights = const [];
  int? _selectedFlightId;

  List<Map<String, dynamic>> _announcements = const [];

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _loadingFlights = true;
      _error = null;
    });

    try {
      final raw = await ApiService.staffListFlights();
      final flights = <Map<String, dynamic>>[];
      for (final f in raw) {
        if (f is Map) flights.add(f.cast<String, dynamic>());
      }

      int? selected;
      if (flights.isNotEmpty) {
        final firstId = flights.first['id'];
        selected = firstId is int
            ? firstId
            : int.tryParse(firstId?.toString() ?? '');
      }

      if (!mounted) return;
      setState(() {
        _flights = flights;
        _selectedFlightId = selected;
        _loadingFlights = false;
      });

      if (selected != null) {
        await _loadAnnouncements(selected);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingFlights = false;
      });
    }
  }

  Future<void> _loadAnnouncements(int flightId) async {
    setState(() {
      _loadingAnnouncements = true;
      _error = null;
    });

    try {
      final raw = await ApiService.staffGetAnnouncementsForFlight(flightId);
      final items = <Map<String, dynamic>>[];
      for (final a in raw) {
        if (a is Map) items.add(a.cast<String, dynamic>());
      }

      if (!mounted) return;
      setState(() {
        _announcements = items;
        _loadingAnnouncements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingAnnouncements = false;
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final flightId = _selectedFlightId;
    if (flightId == null) return;

    final msgController = TextEditingController();
    const types = ['INFO', 'DELAY', 'GATE_CHANGE', 'CANCELLATION'];
    String selectedType = 'INFO';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Новое объявление',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  selectedType = v;
                },
                decoration: const InputDecoration(labelText: 'Тип'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Сообщение'),
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
                'Опубликовать',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await ApiService.staffCreateAnnouncement(
        flightId: flightId,
        message: msgController.text.trim(),
        type: selectedType,
      );
      await _loadAnnouncements(flightId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Объявление опубликовано')));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Ошибка публикации' : msg)),
      );
    }
  }

  Future<void> _editAnnouncement(Map<String, dynamic> a) async {
    final idRaw = a['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    final flightId = _selectedFlightId;
    if (id == null || flightId == null) return;

    final msgController = TextEditingController(
      text: (a['message'] ?? '').toString(),
    );

    const types = ['INFO', 'DELAY', 'GATE_CHANGE', 'CANCELLATION'];
    String selectedType = (a['announcement_type']?.toString() ?? 'INFO');
    if (!types.contains(selectedType)) selectedType = 'INFO';

    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Редактирование',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  selectedType = v;
                },
                decoration: const InputDecoration(labelText: 'Тип'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Сообщение'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text('Отмена', style: GoogleFonts.montserrat()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: Text(
                'Удалить',
                style: GoogleFonts.montserrat(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'save'),
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

    if (action == null || action == 'cancel') return;

    try {
      if (action == 'delete') {
        await ApiService.staffDeleteAnnouncement(id);
      } else {
        await ApiService.staffUpdateAnnouncement(
          id,
          message: msgController.text.trim(),
          type: selectedType,
        );
      }

      await _loadAnnouncements(flightId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'delete' ? 'Удалено' : 'Сохранено')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg.isEmpty ? 'Ошибка' : msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flightItems = _flights
        .map((f) {
          final idRaw = f['id'];
          final id = idRaw is int
              ? idRaw
              : int.tryParse(idRaw?.toString() ?? '');
          final fn = f['flight_number']?.toString() ?? '';
          if (id == null) return null;
          return DropdownMenuItem<int>(
            value: id,
            child: Text(fn.isEmpty ? 'Рейс $id' : fn),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Публикация объявлений',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingFlights)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                value: _selectedFlightId,
                items: flightItems,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selectedFlightId = v);
                  await _loadAnnouncements(v);
                },
                decoration: const InputDecoration(labelText: 'Рейс'),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFlightId == null
                    ? null
                    : _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZaKuColors.gold,
                  foregroundColor: ZaKuColors.burgundy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Добавить объявление',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: GoogleFonts.montserrat(color: Colors.red),
                ),
              ),
            Expanded(
              child: _loadingAnnouncements
                  ? const Center(child: CircularProgressIndicator())
                  : (_announcements.isEmpty
                        ? Center(
                            child: Text(
                              'Нет объявлений',
                              style: GoogleFonts.montserrat(
                                color: ZaKuColors.darkGrey.withOpacity(0.7),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _announcements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final a = _announcements[index];
                              final type =
                                  a['announcement_type']?.toString() ?? '';
                              final msg = a['message']?.toString() ?? '';
                              return InkWell(
                                onTap: () => _editAnnouncement(a),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.isEmpty ? 'INFO' : type,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w800,
                                          color: ZaKuColors.burgundy,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.isEmpty ? '—' : msg,
                                        style: GoogleFonts.montserrat(),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Нажмите для редактирования',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: ZaKuColors.darkGrey
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
