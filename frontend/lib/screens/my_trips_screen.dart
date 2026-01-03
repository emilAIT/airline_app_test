// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import '../utils/bishkek_time.dart';
import 'booking_pending_screen.dart';
import 'trip_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookings = const [];
  final Map<int, Map<String, dynamic>> _flightsById = {};
  Map<String, dynamic>? _profile;

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
      Map<String, dynamic>? profile;
      try {
        profile = await ApiService.getMyProfile();
      } catch (_) {
        // Best-effort: profile is optional for trips list.
      }
      final raw = await ApiService.getMyBookings();
      final bookings = <Map<String, dynamic>>[];
      final flightIds = <int>{};

      for (final b in raw) {
        if (b is Map) {
          final m = b.cast<String, dynamic>();
          bookings.add(m);
          final fid = m['flight_id'];
          final fidInt = fid is int ? fid : int.tryParse(fid?.toString() ?? '');
          if (fidInt != null) flightIds.add(fidInt);
        }
      }

      for (final fid in flightIds) {
        if (_flightsById.containsKey(fid)) continue;
        final f = await ApiService.getFlight(fid);
        if (f != null) _flightsById[fid] = f;
      }

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _profile = profile;
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

  DateTime? _parseIso(dynamic v) {
    return BishkekTime.parseServerUtc(v);
  }

  String _fmtDateTime(DateTime dt) {
    return BishkekTime.fmtYmdHm(dt);
  }

  bool _isWithin24hToDeparture(DateTime? departure) {
    if (departure == null) return false;
    final now = DateTime.now().toUtc();
    final depUtc = departure.isUtc ? departure : departure.toUtc();
    final diff = depUtc.difference(now);
    return diff.inHours < 24 && diff.inMinutes > 60;
  }

  Future<void> _checkIn(Map<String, dynamic> booking) async {
    final id = booking['id'];
    final bookingId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (bookingId == null) return;

    try {
      final result = await ApiService.checkInBooking(bookingId);
      if (result == null) return;

      if (!mounted) return;
      setState(() {
        // Update status locally
        booking['status'] = result['status'] ?? 'CHECKED_IN';
      });

      await _showBoardingPass(booking, checkInResult: result);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Ошибка check-in' : msg)),
      );
    }
  }

  Future<void> _showBoardingPass(
    Map<String, dynamic> booking, {
    Map<String, dynamic>? checkInResult,
  }) async {
    final pnr = booking['pnr']?.toString() ?? '';
    final tickets = (booking['tickets'] is List)
        ? (booking['tickets'] as List)
        : const [];

    List<Map<String, dynamic>> passes = [];
    if (checkInResult != null && checkInResult['items'] is List) {
      passes = (checkInResult['items'] as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } else {
      // Best-effort: fetch boarding pass per ticket number
      for (final t in tickets) {
        if (t is! Map) continue;
        final tn = t['ticket_number']?.toString();
        if (tn == null || tn.isEmpty) continue;
        try {
          final bp = await ApiService.getBoardingPass(tn);
          if (bp != null) passes.add(bp);
        } catch (_) {
          // If not checked-in yet, backend will return error.
        }
      }
    }

    if (!mounted) return;

    final profileFirst = _profile?['first_name']?.toString() ?? '';
    final profileLast = _profile?['last_name']?.toString() ?? '';
    final profileName = ('$profileFirst $profileLast').trim();
    final overrideSingleName = profileName.isNotEmpty && passes.length == 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Посадочный талон',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (pnr.isNotEmpty)
                  Text(
                    'PNR: $pnr',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 12),
                if (passes.isEmpty)
                  Text(
                    'Сначала выполните online check-in (за 24 часа до вылета), чтобы получить QR.',
                    style: GoogleFonts.montserrat(
                      color: ZaKuColors.darkGrey.withOpacity(0.75),
                    ),
                  )
                else
                  ...passes.map((p) {
                    final qr = p['boarding_pass_qr']?.toString() ?? '';
                    final seat = p['seat_number']?.toString() ?? '';
                    final rawName = p['passenger_name']?.toString() ?? '';
                    final name = overrideSingleName ? profileName : rawName;
                    final tn = p['ticket_number']?.toString() ?? '';
                    final fn = p['flight_number']?.toString() ?? '';
                    final gate = p['gate']?.toString() ?? '';
                    final btRaw = p['boarding_time']?.toString();
                    final bt = btRaw == null ? null : _parseIso(btRaw);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            name.isEmpty ? 'Пассажир' : name,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Рейс: ${fn.isEmpty ? '—' : fn}',
                            style: GoogleFonts.montserrat(),
                          ),
                          Text(
                            'Место: ${seat.isEmpty ? '—' : seat}',
                            style: GoogleFonts.montserrat(),
                          ),
                          Text(
                            'Выход: ${gate.trim().isEmpty ? '—' : gate}',
                            style: GoogleFonts.montserrat(),
                          ),
                          Text(
                            'Посадка: ${bt == null ? '—' : _fmtDateTime(bt)}',
                            style: GoogleFonts.montserrat(),
                          ),
                          if (tn.isNotEmpty)
                            Text('Билет: $tn', style: GoogleFonts.montserrat()),
                          const SizedBox(height: 12),
                          if (qr.isNotEmpty)
                            Center(
                              child: QrImageView(
                                data: qr,
                                size: 180,
                                backgroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = DateTime.now().toUtc();
    bool isPastDeparture(Map<String, dynamic> booking) {
      final fid = booking['flight_id'];
      final flightId = fid is int ? fid : int.tryParse(fid?.toString() ?? '');
      final flight = flightId == null ? null : _flightsById[flightId];
      final dep = _parseIso(flight?['departure_time']);
      if (dep == null) return false;
      final depUtc = dep.isUtc ? dep : dep.toUtc();
      return depUtc.isBefore(nowUtc);
    }

    final active = _bookings.where((b) {
      final status = b['status']?.toString() ?? '';
      if (status == 'CANCELLED') return false;
      return !isPastDeparture(b);
    }).toList();

    final history = _bookings.where((b) {
      final status = b['status']?.toString() ?? '';
      if (status == 'CANCELLED') return true;
      return isPastDeparture(b);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Мои поездки',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          backgroundColor: ZaKuColors.burgundy,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: 'Активные (${active.length})'),
              Tab(text: 'История (${history.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.montserrat(color: Colors.red),
                      ),
                    )
                  : TabBarView(
                      children: [
                        _BookingList(
                          bookings: active,
                          flightsById: _flightsById,
                          parseIso: _parseIso,
                          within24h: _isWithin24hToDeparture,
                          onCheckIn: _checkIn,
                          onViewBoardingPass: (b) => _showBoardingPass(b),
                          onPay: (b) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingPendingScreen(booking: b),
                              ),
                            );
                            await _load();
                          },
                          onOpenDetails: (b) async {
                            final fid = b['flight_id'];
                            final flightId = fid is int
                                ? fid
                                : int.tryParse(fid?.toString() ?? '');
                            final flight = flightId == null
                                ? null
                                : _flightsById[flightId];
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripDetailsScreen(
                                  booking: b,
                                  flight: flight,
                                ),
                              ),
                            );
                            await _load();
                          },
                        ),
                        _BookingList(
                          bookings: history,
                          flightsById: _flightsById,
                          parseIso: _parseIso,
                          within24h: (_) => false,
                          onCheckIn: (_) async {},
                          onViewBoardingPass: (_) async {},
                          onOpenDetails: (b) async {
                            final fid = b['flight_id'];
                            final flightId = fid is int
                                ? fid
                                : int.tryParse(fid?.toString() ?? '');
                            final flight = flightId == null
                                ? null
                                : _flightsById[flightId];
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripDetailsScreen(
                                  booking: b,
                                  flight: flight,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final Map<int, Map<String, dynamic>> flightsById;
  final DateTime? Function(dynamic) parseIso;
  final bool Function(DateTime?) within24h;
  final Future<void> Function(Map<String, dynamic>) onCheckIn;
  final Future<void> Function(Map<String, dynamic>) onViewBoardingPass;
  final Future<void> Function(Map<String, dynamic>)? onOpenDetails;
  final Future<void> Function(Map<String, dynamic>)? onPay;

  const _BookingList({
    required this.bookings,
    required this.flightsById,
    required this.parseIso,
    required this.within24h,
    required this.onCheckIn,
    required this.onViewBoardingPass,
    this.onOpenDetails,
    this.onPay,
  });

  DateTime? _parseServerUtc(dynamic v) {
    return BishkekTime.parseServerUtc(v);
  }

  String _formatDate(DateTime? dt) {
    return BishkekTime.fmtYmdHm(dt);
  }

  String _historyTypeLabel({required String status, required bool isPast}) {
    if (status == 'CANCELLED') return 'Не оплачено';
    if (isPast && (status == 'CONFIRMED' || status == 'CHECKED_IN'))
      return 'Завершено';
    if (isPast) return 'Не оплачено';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text('Нет бронирований', style: GoogleFonts.montserrat()),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = bookings[index];
        final pnr = b['pnr']?.toString() ?? '';
        final status = b['status']?.toString() ?? '';
        final fid = b['flight_id'];
        final flightId = fid is int ? fid : int.tryParse(fid?.toString() ?? '');
        final flight = flightId == null ? null : flightsById[flightId];
        final dep = parseIso(flight?['departure_time']);
        final flightNumber = flight?['flight_number']?.toString() ?? '';

        final nowUtc = DateTime.now().toUtc();
        final depUtc = dep == null ? null : (dep.isUtc ? dep : dep.toUtc());
        final isPast = depUtc != null && depUtc.isBefore(nowUtc);

        final showCheckIn = status == 'CONFIRMED' && within24h(dep);
        // View boarding pass should appear only after check-in.
        final showBoarding = status == 'CHECKED_IN';

        final heldUntil = _parseServerUtc(b['seats_held_until']);
        final canPay =
            status == 'CREATED' &&
            heldUntil != null &&
            heldUntil.isAfter(DateTime.now().toUtc()) &&
            onPay != null;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenDetails == null ? null : () => onOpenDetails!(b),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZaKuColors.gold.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pnr.isEmpty ? 'Бронирование' : 'PNR: $pnr',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ZaKuColors.burgundy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _historyTypeLabel(status: status, isPast: isPast),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: ZaKuColors.burgundy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  flightNumber.isEmpty
                      ? 'Рейс: ${flightId ?? '—'}'
                      : 'Рейс: $flightNumber',
                  style: GoogleFonts.montserrat(
                    color: ZaKuColors.darkGrey.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Вылет: ${_formatDate(dep)}',
                  style: GoogleFonts.montserrat(
                    color: ZaKuColors.darkGrey.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                if (canPay)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onPay!(b),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZaKuColors.gold,
                        foregroundColor: ZaKuColors.burgundy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Оплатить',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (showCheckIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onCheckIn(b),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZaKuColors.gold,
                        foregroundColor: ZaKuColors.burgundy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Онлайн регистрация',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (showBoarding)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => onViewBoardingPass(b),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Открыть посадочный талон',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
