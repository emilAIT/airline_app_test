// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import '../utils/bishkek_time.dart';
import 'booking_pending_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? flight;

  const TripDetailsScreen({super.key, required this.booking, this.flight});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Map<String, dynamic>? _flight;
  Map<int, Map<String, dynamic>> _airportsById = const {};
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _flight = widget.flight;
      final flightIdRaw = widget.booking['flight_id'];
      final flightId = flightIdRaw is int
          ? flightIdRaw
          : int.tryParse(flightIdRaw?.toString() ?? '');
      if (_flight == null && flightId != null) {
        _flight = await ApiService.getFlight(flightId);
      }

      final airports = await ApiService.getAirports();
      final profile = await ApiService.getMyProfile();
      final map = <int, Map<String, dynamic>>{};
      for (final a in airports) {
        if (a is! Map) continue;
        final id = a['id'];
        if (id is int) map[id] = a.cast<String, dynamic>();
      }

      if (!mounted) return;
      setState(() {
        _airportsById = map;
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

  DateTime? _parseServerUtc(dynamic v) {
    return BishkekTime.parseServerUtc(v);
  }

  String _fmtDateTime(DateTime? dt) {
    return BishkekTime.fmtYmdHm(dt);
  }

  String _airportLabel(int? id) {
    if (id == null) return '—';
    final a = _airportsById[id];
    if (a == null) return '$id';
    final code = a['code']?.toString() ?? '';
    final city = a['city']?.toString() ?? '';
    if (code.isNotEmpty && city.isNotEmpty) return '$code • $city';
    return code.isNotEmpty ? code : (city.isNotEmpty ? city : '$id');
  }

  DateTime? _boardingTime(DateTime? departure) {
    if (departure == null) return null;
    return departure.subtract(const Duration(minutes: 30));
  }

  Future<void> _openPayment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPendingScreen(booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pnr = widget.booking['pnr']?.toString() ?? '';
    final status = widget.booking['status']?.toString() ?? '';
    final heldUntil = _parseServerUtc(widget.booking['seats_held_until']);
    final tickets = (widget.booking['tickets'] is List)
        ? (widget.booking['tickets'] as List)
        : const [];
    final passengers = (widget.booking['passengers'] is List)
        ? (widget.booking['passengers'] as List)
        : const [];

    final profileFirst = _profile?['first_name']?.toString() ?? '';
    final profileLast = _profile?['last_name']?.toString() ?? '';
    final profileName = ('$profileFirst $profileLast').trim();
    final overrideSingleName =
        profileName.isNotEmpty &&
        (passengers.length == 1 || tickets.length == 1);

    final flightNumber = _flight?['flight_number']?.toString() ?? '';
    final originId = _flight?['origin_id'];
    final destinationId = _flight?['destination_id'];
    final dep = _parseIso(_flight?['departure_time']);
    final arr = _parseIso(_flight?['arrival_time']);
    final terminal = _flight?['terminal']?.toString();
    final gate = _flight?['gate']?.toString();
    final boarding = _boardingTime(dep);
    final airplaneModel = _flight?['airplane_model']?.toString();
    final airplaneReg = _flight?['airplane_registration']?.toString();
    final airplane = airplaneModel ?? airplaneReg;

    final canPay =
        status == 'CREATED' &&
        heldUntil != null &&
        heldUntil.isAfter(DateTime.now().toUtc());
    final isBoarding = status == 'CHECKED_IN';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pnr.isEmpty ? 'Детали поездки' : 'PNR $pnr',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _card(
                        title: 'Бронирование',
                        children: [
                          _kv('PNR', pnr),
                          _kv('Статус', status),
                          if (heldUntil != null && status == 'CREATED')
                            _kv('Удержание до', _fmtDateTime(heldUntil)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Рейс',
                        children: [
                          _kv(
                            'Номер',
                            flightNumber.isEmpty ? '—' : flightNumber,
                          ),
                          if (airplane != null && airplane.trim().isNotEmpty)
                            _kv('Самолёт', airplane),
                          _kv(
                            'Маршрут',
                            '${_airportLabel(_toInt(originId))} → ${_airportLabel(_toInt(destinationId))}',
                          ),
                          _kvDatetime('Вылет', dep),
                          _kvDatetime('Прилёт', arr),
                          if (terminal != null && terminal.trim().isNotEmpty)
                            _kv('Терминал', terminal),
                          if (gate != null && gate.trim().isNotEmpty)
                            _kv('Выход', gate),
                          _kvDatetime('Посадка', boarding),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Пассажиры и билеты',
                        children: [
                          if (passengers.isEmpty && tickets.isEmpty)
                            Text('—', style: GoogleFonts.montserrat())
                          else ...[
                            for (final p in passengers)
                              if (p is Map)
                                _passengerRow(
                                  p.cast<String, dynamic>(),
                                  overrideName: overrideSingleName
                                      ? profileName
                                      : null,
                                ),
                            if (passengers.isEmpty)
                              for (final t in tickets)
                                if (t is Map)
                                  _ticketRow(
                                    t.cast<String, dynamic>(),
                                    overrideName: overrideSingleName
                                        ? profileName
                                        : null,
                                  ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!isBoarding && status == 'CREATED')
                        _card(
                          title: 'Действия',
                          children: [
                            if (canPay)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _openPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ZaKuColors.gold,
                                    foregroundColor: ZaKuColors.burgundy,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                            else
                              Text(
                                'Удержание мест истекло или отсутствует. Обновите "Мои поездки", чтобы увидеть актуальный статус.',
                                style: GoogleFonts.montserrat(
                                  color: ZaKuColors.darkGrey.withOpacity(0.75),
                                ),
                              ),
                          ],
                        )
                      else
                        _BoardingPassSection(
                          tickets: tickets,
                          flightNumber: flightNumber,
                          gate: (gate == null || gate.trim().isEmpty)
                              ? null
                              : gate,
                          boardingTime: boarding,
                          overridePassengerName: overrideSingleName
                              ? profileName
                              : null,
                        ),
                    ],
                  )),
    );
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZaKuColors.gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: ZaKuColors.darkGrey.withOpacity(0.75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.trim().isEmpty ? '—' : v,
              style: GoogleFonts.montserrat(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvDatetime(String k, DateTime? dt) {
    if (dt == null) return _kv(k, '—');
    final date = BishkekTime.fmtDate(dt);
    final time = BishkekTime.fmtTime(dt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: ZaKuColors.darkGrey.withOpacity(0.75),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                Text(
                  time,
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passengerRow(Map<String, dynamic> p, {String? overrideName}) {
    final rawName = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final name = (overrideName != null && overrideName.trim().isNotEmpty)
        ? overrideName.trim()
        : rawName;
    final seat = p['seat_number']?.toString() ?? '';
    final ticket = p['ticket_number']?.toString() ?? '';
    final price = _ticketPriceFor(ticketNumber: ticket, tickets: null);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Пассажир' : name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Билет: ${ticket.isEmpty ? '—' : ticket}',
            style: GoogleFonts.montserrat(),
          ),
          Text(
            'Место: ${seat.isEmpty ? '—' : seat}',
            style: GoogleFonts.montserrat(),
          ),
          Text('Цена: ${price ?? '—'}', style: GoogleFonts.montserrat()),
        ],
      ),
    );
  }

  Widget _ticketRow(Map<String, dynamic> t, {String? overrideName}) {
    final rawName =
        '${t['passenger_first_name'] ?? ''} ${t['passenger_last_name'] ?? ''}'
            .trim();
    final name = (overrideName != null && overrideName.trim().isNotEmpty)
        ? overrideName.trim()
        : rawName;
    
    // Get seat info from nested seat object or fallback to seat_number
    String seatDisplay = '';
    if (t['seat'] is Map) {
      final seatObj = t['seat'] as Map<String, dynamic>;
      final row = seatObj['row_number'];
      final letter = seatObj['seat_letter'];
      final category = seatObj['category'];
      
      if (row != null && letter != null) {
        seatDisplay = '$row$letter';
        if (category == 'extra_legroom') {
          seatDisplay += ' (Extra Legroom)';
        }
      }
    } else {
      seatDisplay = t['seat_number']?.toString() ?? '';
    }
    
    final ticket = t['ticket_number']?.toString() ?? '';
    final price = _formatMoney(t['price']);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Пассажир' : name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Билет: ${ticket.isEmpty ? '—' : ticket}',
            style: GoogleFonts.montserrat(),
          ),
          Text(
            'Место: ${seatDisplay.isEmpty ? '—' : seatDisplay}',
            style: GoogleFonts.montserrat(),
          ),
          Text('Цена: ${price ?? '—'}', style: GoogleFonts.montserrat()),
        ],
      ),
    );
  }

  String? _formatMoney(dynamic v) {
    if (v == null) return null;
    final n = v is num ? v : num.tryParse(v.toString());
    if (n == null) return null;
    return '${n.toStringAsFixed(0)} с';
  }

  String? _ticketPriceFor({
    required String ticketNumber,
    required List<dynamic>? tickets,
  }) {
    if (ticketNumber.trim().isEmpty) return null;
    final list =
        tickets ??
        (widget.booking['tickets'] is List
            ? (widget.booking['tickets'] as List)
            : const []);
    for (final t in list) {
      if (t is! Map) continue;
      final tn = t['ticket_number']?.toString() ?? '';
      if (tn == ticketNumber) return _formatMoney(t['price']);
    }
    return null;
  }
}

class _BoardingPassSection extends StatefulWidget {
  final List<dynamic> tickets;
  final String flightNumber;
  final String? gate;
  final DateTime? boardingTime;
  final String? overridePassengerName;

  const _BoardingPassSection({
    required this.tickets,
    required this.flightNumber,
    required this.gate,
    required this.boardingTime,
    this.overridePassengerName,
  });

  @override
  State<_BoardingPassSection> createState() => _BoardingPassSectionState();
}

class _BoardingPassSectionState extends State<_BoardingPassSection> {
  bool _loading = true;
  List<Map<String, dynamic>> _passes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final passes = <Map<String, dynamic>>[];

    for (final t in widget.tickets) {
      if (t is! Map) continue;
      final tn = t['ticket_number']?.toString();
      if (tn == null || tn.isEmpty) continue;
      try {
        final bp = await ApiService.getBoardingPass(tn);
        if (bp != null) passes.add(bp);
      } catch (_) {
        // ignore
      }
    }

    if (!mounted) return;
    setState(() {
      _passes = passes;
      _loading = false;
    });
  }

  String _fmt(DateTime? dt) {
    return BishkekTime.fmtHm(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Посадочный талон',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_passes.isEmpty)
            Text('Посадочный талон не найден.', style: GoogleFonts.montserrat())
          else
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final p in _passes) ...[
                      _bpCard(p),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bpCard(Map<String, dynamic> p) {
    final rawName = p['passenger_name']?.toString() ?? '';
    final name =
        (widget.overridePassengerName != null &&
            widget.overridePassengerName!.trim().isNotEmpty)
        ? widget.overridePassengerName!.trim()
        : rawName;
    final seat = p['seat_number']?.toString() ?? '';
    final tn = p['ticket_number']?.toString() ?? '';
    final qr = p['boarding_pass_qr']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZaKuColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZaKuColors.gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Пассажир' : name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Рейс: ${widget.flightNumber.isEmpty ? '—' : widget.flightNumber}',
            style: GoogleFonts.montserrat(),
          ),
          Text(
            'Место: ${seat.isEmpty ? '—' : seat}',
            style: GoogleFonts.montserrat(),
          ),
          Text('Выход: ${widget.gate ?? '—'}', style: GoogleFonts.montserrat()),
          Text(
            'Посадка: ${_fmt(widget.boardingTime)}',
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
  }
}
