// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import '../utils/bishkek_time.dart';
import 'seat_selection_screen.dart';

// ЭКРАН ПОИСКА
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Map<String, dynamic>? selectedFrom;
  Map<String, dynamic>? selectedTo;
  // Default to today so users can find flights departing soon (e.g. next 3–7 hours)
  // without having to change the date manually.
  DateTime selectedDate = DateTime.now();
  String selectedClass = 'Эконом';
  List<dynamic> airports = [];
  bool isLoadingAirports = true;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    final data = await ApiService.getAirports();
    if (mounted) {
      setState(() {
        airports = data;
        isLoadingAirports = false;
        if (airports.isNotEmpty) {
          selectedFrom = airports.first;
          if (airports.length > 1) {
            selectedTo = airports[1];
          }
        }
      });
    }
  }

  List<Map<String, String>> _offersForAvailableAirports() {
    String imageForCode(String code) {
      switch (code.toUpperCase()) {
        case 'ALA':
          return 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=800';
        case 'NQZ':
          return 'https://images.unsplash.com/photo-1526779259212-939e64788e3c?w=800';
        case 'DXB':
          return 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800';
        default:
          return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';
      }
    }

    final out = <Map<String, String>>[];
    for (final a in airports) {
      if (a is! Map) continue;
      final code = a['code']?.toString();
      final city = a['city']?.toString();
      if (code == null || code.isEmpty) continue;
      out.add({
        'code': code,
        'title': (city == null || city.isEmpty) ? code : city,
        'subtitle': code,
        'cta': 'Смотреть рейсы',
        'imageUrl': imageForCode(code),
      });
    }

    // Keep UI tidy: show up to 4 offers.
    if (out.length > 4) {
      return out.take(4).toList();
    }
    return out;
  }

  void _handleSearch() async {
    if (selectedFrom == null || selectedTo == null) return;

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

    List<dynamic> results = [];
    Object? error;
    try {
      results = await ApiService.searchFlights(
        selectedFrom!['id'],
        selectedTo!['id'],
        selectedDate,
      );
    } catch (e) {
      error = e;
    } finally {
      if (mounted && loaderShown) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      }
    }

    if (!mounted) return;

    if (error != null) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Ошибка при поиске рейсов' : msg)),
      );
      return;
    }

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рейсов не найдено на эту дату')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Доступные рейсы',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final flight = results[index];
                  // Валюта - сом
                  const currency = 'с';

                  Map<String, dynamic>? airportById(dynamic id) {
                    if (id == null) return null;
                    final intId = id is int ? id : int.tryParse(id.toString());
                    if (intId == null) return null;
                    for (final a in airports) {
                      if (a is Map && a['id'] == intId) {
                        return a.cast<String, dynamic>();
                      }
                    }
                    return null;
                  }

                  DateTime? parseIso(dynamic v) {
                    return BishkekTime.parseServerUtc(v);
                  }

                  String formatHm(DateTime? dt) {
                    return BishkekTime.fmtDdMmHm(dt);
                  }

                  String formatDuration(DateTime? dep, DateTime? arr) {
                    if (dep == null || arr == null) return '';
                    final diff = arr.difference(dep);
                    if (diff.isNegative) return '';
                    final h = diff.inHours;
                    final m = diff.inMinutes.remainder(60);
                    if (h <= 0) return '$mм';
                    if (m == 0) return '$hч';
                    return '$hч $mм';
                  }

                  num? asNum(dynamic v) {
                    if (v is num) return v;
                    if (v == null) return null;
                    return num.tryParse(v.toString());
                  }

                  final depTime = parseIso(flight['departure_time']);
                  final arrTime = parseIso(flight['arrival_time']);
                  final depStr = formatHm(depTime);
                  final arrStr = formatHm(arrTime);
                  final depDate = depTime != null ? BishkekTime.fmtDate(depTime) : '';

                  final originAirport =
                      (flight is Map && flight['origin_airport'] is Map)
                      ? (flight['origin_airport'] as Map)
                            .cast<String, dynamic>()
                      : airportById(flight['origin_id']);
                  final destinationAirport =
                      (flight is Map && flight['destination_airport'] is Map)
                      ? (flight['destination_airport'] as Map)
                            .cast<String, dynamic>()
                      : airportById(flight['destination_id']);

                  final duration = (flight is Map && flight['duration'] != null)
                      ? flight['duration'].toString()
                      : formatDuration(depTime, arrTime);

                  final price = asNum(
                    (flight is Map)
                        ? (flight['base_price'] ?? flight['price'])
                        : null,
                  );

                  final airplaneModel = flight['airplane_model']?.toString();
                  final airplaneReg = flight['airplane_registration']?.toString();

                  final availableSeatsNum = asNum(
                    (flight is Map)
                        ? (flight['available_seats'] ??
                              flight['seats_available'] ??
                              flight['availableSeats'])
                        : null,
                  )?.toInt();
                  final hasAvailability = availableSeatsNum != null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeatSelectionScreen(
                            flight: flight,
                            airports: airports,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: ZaKuColors.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flight,
                                    color: ZaKuColors.burgundy,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    flight['flight_number'],
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (hasAvailability)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: availableSeatsNum > 5
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$availableSeatsNum мест',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          color: availableSeatsNum > 5
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${(price ?? 0).toStringAsFixed(0)} $currency',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: ZaKuColors.gold,
                                ),
                              ),
                            ],
                          ),
                          if (depDate.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  depDate,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (airplaneModel != null || airplaneReg != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.flight, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  airplaneModel ?? airplaneReg ?? '',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRouteInfo(
                                (originAirport?['code'] ?? '--').toString(),
                                (originAirport?['city'] ?? '').toString(),
                                true,
                                depStr,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      duration,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ZaKuColors.darkGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.flight_takeoff,
                                      color: ZaKuColors.gold,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      flight['status'],
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildRouteInfo(
                                (destinationAirport?['code'] ?? '--')
                                    .toString(),
                                (destinationAirport?['city'] ?? '').toString(),
                                false,
                                arrStr,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(String code, String city, bool isStart, String time) {
    return Column(
      crossAxisAlignment: isStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          time,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ZaKuColors.darkGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          code,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ZaKuColors.burgundy,
          ),
        ),
        Text(
          city,
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingAirports) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ZaKuColors.burgundy,
                      ZaKuColors.burgundy.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: ZaKuColors.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.explore,
                                  color: ZaKuColors.burgundy,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ZaKu',
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: ZaKuColors.gold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Добро пожаловать',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Куда отправимся сегодня?',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildLocationField(
                        label: 'Откуда',
                        value: selectedFrom?['city'] ?? 'Выбрать',
                        icon: Icons.flight_takeoff,
                        onTap: () => _selectCity(true),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ZaKuColors.gold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.swap_vert,
                              color: ZaKuColors.gold,
                            ),
                            onPressed: () {
                              setState(() {
                                final temp = selectedFrom;
                                selectedFrom = selectedTo;
                                selectedTo = temp;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationField(
                        label: 'Куда',
                        value: selectedTo?['city'] ?? 'Выбрать',
                        icon: Icons.flight_land,
                        onTap: () => _selectCity(false),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      _buildDateField(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZaKuColors.gold,
                            foregroundColor: ZaKuColors.burgundy,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Найти идеальный рейс',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZaKuColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZaKuColors.lightGrey.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ZaKuColors.burgundy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ZaKuColors.burgundy, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: ZaKuColors.darkGrey.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ZaKuColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: ZaKuColors.darkGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZaKuColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZaKuColors.lightGrey.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: ZaKuColors.burgundy.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Дата',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: ZaKuColors.darkGrey.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ZaKuColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassField() {
    return GestureDetector(
      onTap: () {
        final classes = ['Эконом', 'Бизнес', 'Первый'];
        showModalBottomSheet(
          context: context,
          builder: (context) => ListView(
            shrinkWrap: true,
            children: classes
                .map(
                  (c) => ListTile(
                    title: Text(
                      c,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() => selectedClass = c);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZaKuColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZaKuColors.lightGrey.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.airline_seat_recline_extra,
                  size: 16,
                  color: ZaKuColors.burgundy.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Класс',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: ZaKuColors.darkGrey.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              selectedClass,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ZaKuColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String subtitle,
    required String cta,
    required String imageUrl,
    required String destinationCode,
  }) {
    void handleTap() {
      if (airports.isEmpty) return;

      Map<String, dynamic>? findByCode(String code) {
        for (final a in airports) {
          if (a is Map &&
              a['code']?.toString().toUpperCase() == code.toUpperCase()) {
            return a.cast<String, dynamic>();
          }
        }
        return null;
      }

      final dest = findByCode(destinationCode);
      if (dest == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Направление недоступно')));
        return;
      }

      setState(() {
        selectedTo = dest;

        // Ensure origin is set and differs from destination.
        selectedFrom ??= airports.first is Map
            ? (airports.first as Map).cast<String, dynamic>()
            : null;
        if (selectedFrom != null && selectedFrom!['id'] == selectedTo!['id']) {
          final fallback = airports.firstWhere(
            (a) => a is Map && a['id'] != selectedTo!['id'],
            orElse: () => airports.first,
          );
          if (fallback is Map) selectedFrom = fallback.cast<String, dynamic>();
        }

        if (selectedDate.isBefore(DateTime.now())) {
          selectedDate = DateTime.now().add(const Duration(days: 1));
        }
      });

      _handleSearch();
    }

    return GestureDetector(
      onTap: handleTap,
      child: SizedBox(
        width: 220,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      color: ZaKuColors.lightGrey.withOpacity(0.3),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ZaKuColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cta,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ZaKuColors.burgundy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectCity(bool isFrom) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: airports
            .map(
              (airport) => ListTile(
                title: Text(airport['city']),
                subtitle: Text('${airport['code']} - ${airport['country']}'),
                onTap: () {
                  setState(
                    () =>
                        isFrom ? selectedFrom = airport : selectedTo = airport,
                  );
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
