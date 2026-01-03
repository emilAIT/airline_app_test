// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import '../utils/bishkek_time.dart';

class StaffBookingsScreen extends StatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  State<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends State<StaffBookingsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookings = const [];

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
      final raw = await ApiService.staffListBookings();
      final items = <Map<String, dynamic>>[];
      for (final b in raw) {
        if (b is Map) items.add(b.cast<String, dynamic>());
      }

      if (!mounted) return;
      setState(() {
        _bookings = items;
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

  String _fmtDt(dynamic v) {
    final dt = BishkekTime.parseServerUtc(v);
    return BishkekTime.fmtYmdHm(dt);
  }

  String _fmtPrice(dynamic v) {
    if (v == null) return '—';
    final n = v is num ? v : num.tryParse(v.toString());
    if (n == null) return '—';
    return '${n.toStringAsFixed(0)} с';
  }

  Future<void> _editBooking(Map<String, dynamic> booking) async {
    final idRaw = booking['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    if (id == null) return;

    const statuses = ['CREATED', 'CONFIRMED', 'CANCELLED', 'CHECKED_IN'];
    String selected = booking['status']?.toString() ?? 'CREATED';
    if (!statuses.contains(selected)) selected = 'CREATED';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Статус брони',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: DropdownButtonFormField<String>(
            value: selected,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              selected = v;
            },
            decoration: const InputDecoration(labelText: 'Статус'),
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

    try {
      await ApiService.staffUpdateBooking(id, status: selected);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Бронь обновлена')));
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
          'Управление бронями',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
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
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        final pnr = b['pnr']?.toString() ?? '';
                        final status = b['status']?.toString() ?? '';
                        final flightId = b['flight_id']?.toString() ?? '';
                        final userId = b['user_id']?.toString() ?? '';
                        final amount = _fmtPrice(b['total_amount']);
                        final createdAt = _fmtDt(b['created_at']);

                        return InkWell(
                          onTap: () => _editBooking(b),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pnr.isEmpty ? 'Бронь' : 'PNR $pnr',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700,
                                        color: ZaKuColors.burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Рейс ID: ${flightId.isEmpty ? '—' : flightId}',
                                  style: GoogleFonts.montserrat(),
                                ),
                                Text(
                                  'Пользователь ID: ${userId.isEmpty ? '—' : userId}',
                                  style: GoogleFonts.montserrat(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Сумма: $amount',
                                  style: GoogleFonts.montserrat(
                                    color: ZaKuColors.darkGrey.withOpacity(
                                      0.75,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Создано: $createdAt',
                                  style: GoogleFonts.montserrat(
                                    color: ZaKuColors.darkGrey.withOpacity(
                                      0.75,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Нажмите для редактирования статуса',
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
