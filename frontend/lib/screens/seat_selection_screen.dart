// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/zaku_colors.dart';
import 'auth_screen.dart';
import 'booking_pending_screen.dart';
import 'passenger_details_screen.dart';
import 'profile_edit_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final dynamic flight;
  final List<dynamic>? airports;
  const SeatSelectionScreen({super.key, required this.flight, this.airports});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<dynamic> seats = [];
  bool isLoading = true;
  Set<String> selectedSeats = {};
  int passengerCount = 1;

  bool _isProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    bool has(String key) => (profile[key] ?? '').toString().trim().isNotEmpty;
    return has('first_name') &&
        has('last_name') &&
        has('passport_number') &&
        has('nationality') &&
        has('date_of_birth');
  }

  Future<bool> _ensureProfileForSinglePassenger() async {
    try {
      final p = await ApiService.getMyProfile();
      if (_isProfileComplete(p)) return true;
    } catch (_) {
      // If profile endpoint fails, fall back to forcing user to edit profile.
    }

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );

    if (updated != true) return false;

    try {
      final p2 = await ApiService.getMyProfile();
      return _isProfileComplete(p2);
    } catch (_) {
      return false;
    }
  }

  Future<void> _createSinglePassengerBooking() async {
    if (!mounted) return;

    final ok = await _ensureProfileForSinglePassenger();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните профиль пассажира, чтобы купить 1 билет'),
        ),
      );
      return;
    }

    bool loaderShown = false;
    if (mounted) {
      loaderShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: ZaKuColors.gold),
        ),
      );
    }

    Map<String, dynamic>? result;
    Object? error;
    try {
      result = await ApiService.createBooking(
        widget.flight['id'],
        selectedSeats.toList(),
      );
      if (result == null) {
        error = Exception('Профиль не заполнен полностью');
      }
    } catch (e) {
      error = e;
    } finally {
      if (mounted && loaderShown) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    }

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бронирование успешно создано!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BookingPendingScreen(booking: result!),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    final msg =
        error?.toString().replaceFirst('Exception: ', '') ??
        'Ошибка создания бронирования. Проверьте данные.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Map<int, Map<String, dynamic>> _airportById() {
    final out = <int, Map<String, dynamic>>{};
    final list = widget.airports;
    if (list == null) return out;
    for (final a in list) {
      if (a is Map && a['id'] is int) {
        out[a['id'] as int] = a.cast<String, dynamic>();
      }
    }
    return out;
  }

  Map<String, dynamic> _normalizeSeat(dynamic s) {
    if (s is! Map) return {};
    final m = s.cast<String, dynamic>();

    // Already in the expected UI format.
    if (m['seat_number'] != null && m['row'] != null && m['letter'] != null) {
      return m;
    }

    // Exam API format: { code: "12A", seat_class, is_occupied, price_markup }
    final code = (m['code'] ?? m['seat_number'])?.toString();
    if (code == null || code.isEmpty) return m;

    final letter = code.substring(code.length - 1);
    final rowStr = code.substring(0, code.length - 1);
    final row = int.tryParse(rowStr);

    final occupied = (m['is_occupied'] == true);
    final status = occupied ? 'occupied' : 'available';

    return {
      ...m,
      'seat_number': code,
      'row': row ?? 0,
      'letter': letter,
      'status': m['status']?.toString() ?? status,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    final data = await ApiService.getSeatMap(widget.flight['id']);
    if (mounted) {
      setState(() {
        seats = data.map(_normalizeSeat).where((e) => e.isNotEmpty).toList();
        isLoading = false;
      });
    }
  }

  void _onSeatTap(String seatNumber, String status) {
    final st = status.toString().toLowerCase();
    if (st != 'available') return;
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        if (selectedSeats.length >= passengerCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Можно выбрать только $passengerCount мест'),
            ),
          );
          return;
        }
        selectedSeats.add(seatNumber);
      }
    });
  }

  void _handleNext() async {
    if (selectedSeats.isEmpty) return;

    if (!AuthService.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

      if (!mounted) return;
      if (result != true) return;
    }

    if (!mounted) return;

    // UX: for a single ticket, auto-use the passenger profile.
    // If profile is incomplete, send the user to profile edit first.
    if (passengerCount <= 1) {
      await _createSinglePassengerBooking();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerDetailsScreen(
          flight: widget.flight,
          selectedSeats: selectedSeats.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seatByNumber = <String, dynamic>{
      for (final s in seats)
        if (s is Map && s['seat_number'] != null)
          s['seat_number'].toString(): s,
    };

    num? asNum(dynamic v) {
      if (v is num) return v;
      if (v == null) return null;
      return num.tryParse(v.toString());
    }

    final basePrice =
        asNum(
          (widget.flight is Map)
              ? ((widget.flight['base_price'] ?? widget.flight['price']))
              : null,
        )?.toDouble() ??
        0.0;

    final airportMap = _airportById();
    final originId = (widget.flight is Map)
        ? asNum(widget.flight['origin_id'])?.toInt()
        : null;
    final destinationId = (widget.flight is Map)
        ? asNum(widget.flight['destination_id'])?.toInt()
        : null;
    final originCode =
        (widget.flight is Map && widget.flight['origin_airport'] is Map)
        ? (widget.flight['origin_airport']['code']?.toString() ?? '')
        : (originId != null
              ? (airportMap[originId]?['code']?.toString() ?? '')
              : '');
    final destinationCode =
        (widget.flight is Map && widget.flight['destination_airport'] is Map)
        ? (widget.flight['destination_airport']['code']?.toString() ?? '')
        : (destinationId != null
              ? (airportMap[destinationId]?['code']?.toString() ?? '')
              : '');

    double seatPrice(dynamic seat) {
      if (seat is Map) {
        final raw = seat['price'];
        final asNumber = asNum(raw);
        if (asNumber != null) return asNumber.toDouble();

        final markup = asNum(seat['price_markup'])?.toDouble();
        if (markup != null) {
          return basePrice * (1.0 + markup);
        }
      }

      return basePrice;
    }

    final totalPrice = selectedSeats.fold<double>(
      0,
      (sum, sn) => sum + seatPrice(seatByNumber[sn]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Выбор мест',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${originCode.isNotEmpty ? originCode : (originId?.toString() ?? '--')} → ${destinationCode.isNotEmpty ? destinationCode : (destinationId?.toString() ?? '--')}',
              style: GoogleFonts.montserrat(fontSize: 11),
            ),
          ],
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        'Пассажиры:',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: ZaKuColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _countButton(
                        icon: Icons.remove,
                        onTap: passengerCount <= 1
                            ? null
                            : () {
                                setState(() {
                                  passengerCount -= 1;
                                  if (selectedSeats.length > passengerCount) {
                                    selectedSeats = selectedSeats
                                        .take(passengerCount)
                                        .toSet();
                                  }
                                });
                              },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$passengerCount',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ZaKuColors.burgundy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _countButton(
                        icon: Icons.add,
                        onTap: () {
                          setState(() => passengerCount += 1);
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${selectedSeats.length}/$passengerCount',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ZaKuColors.darkGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildSeatGrid(),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ВЫБРАНО',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${selectedSeats.length} / $passengerCount',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: ZaKuColors.burgundy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalPrice.toStringAsFixed(0)} с',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: ZaKuColors.darkGrey.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    selectedSeats.length == passengerCount
                                    ? _handleNext
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ZaKuColors.gold,
                                  foregroundColor: ZaKuColors.burgundy,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                child: Text(
                                  'Продолжить',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            _buildLegendItem(
                              'Standard',
                              Colors.white,
                              borderColor: Colors.grey.withOpacity(0.3),
                            ),
                            _buildLegendItem(
                              'Extra Legroom',
                              ZaKuColors.gold.withOpacity(0.15),
                              borderColor: ZaKuColors.gold.withOpacity(0.5),
                            ),
                            _buildLegendItem(
                              'Occupied',
                              Colors.grey.withOpacity(0.35),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: ZaKuColors.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _countButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 18, color: ZaKuColors.burgundy),
      ),
    );
  }

  Widget _buildSeatGrid() {
    // Group seats by row
    final rows = <int, List<dynamic>>{};
    for (final seat in seats) {
      final row = seat is Map ? (seat['row'] as int? ?? 0) : 0;
      if (!rows.containsKey(row)) rows[row] = [];
      rows[row]!.add(seat);
    }

    final sortedRows = rows.keys.toList()..sort();

    return Column(
      children: sortedRows.map((rowNum) {
        final rowSeats = rows[rowNum]!;
        // Sort by letter A,B,C...
        rowSeats.sort((a, b) {
          final la = a is Map ? (a['letter']?.toString() ?? '') : '';
          final lb = b is Map ? (b['letter']?.toString() ?? '') : '';
          return la.compareTo(lb);
        });

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left side (A,B,C)
              ...rowSeats
                  .where(
                    (s) =>
                        s is Map &&
                        'ABC'.contains(s['letter']?.toString() ?? ''),
                  )
                  .map((s) => _buildSeatItem(s)),
              // Aisle
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '$rowNum',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Right side (D,E,F)
              ...rowSeats
                  .where(
                    (s) =>
                        s is Map &&
                        'DEF'.contains(s['letter']?.toString() ?? ''),
                  )
                  .map((s) => _buildSeatItem(s)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatItem(dynamic seat) {
    if (seat is! Map) return const SizedBox.shrink();
    final status = seat['status']?.toString().toLowerCase() ?? '';
    final number = seat['seat_number']?.toString() ?? '';
    final seatClass = seat['seat_class']; // STANDARD or EXTRA_LEGROOM
    final isSelected = selectedSeats.contains(number);
    final isDisabled =
        status == 'sold' ||
        status == 'held' ||
        status == 'occupied' ||
        status == 'locked';

    Color color = Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.3);
    Color textColor = ZaKuColors.darkGrey;

    // Determine base style based on Class
    if (seatClass == 'EXTRA_LEGROOM') {
      color = ZaKuColors.gold.withOpacity(0.15);
      borderColor = ZaKuColors.gold.withOpacity(0.5);
      textColor = ZaKuColors.burgundy;
    }

    // Override with Status
    if (isDisabled) {
      color = Colors.grey.withOpacity(0.35);
      borderColor = Colors.transparent;
      textColor = Colors.white;
    } else if (isSelected) {
      color = ZaKuColors.gold;
      borderColor = ZaKuColors.gold;
      textColor = ZaKuColors.burgundy;
    }

    return GestureDetector(
      onTap: isDisabled ? null : () => _onSeatTap(number, status),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              seat['letter']?.toString() ?? '',
              style: GoogleFonts.montserrat(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (seatClass == 'EXTRA_LEGROOM' &&
                status == 'available' &&
                !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: ZaKuColors.burgundy.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
