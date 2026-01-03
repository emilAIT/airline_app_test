// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import 'create_flight_screen.dart';

class StaffFlightsScreen extends StatefulWidget {
  const StaffFlightsScreen({super.key});

  @override
  State<StaffFlightsScreen> createState() => _StaffFlightsScreenState();
}

class _StaffFlightsScreenState extends State<StaffFlightsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _flights = const [];
  List<Map<String, dynamic>> _filteredFlights = const [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.staffListFlights();
      final flights = <Map<String, dynamic>>[];
      for (final f in raw) {
        if (f is Map) flights.add(f.cast<String, dynamic>());
      }

      if (!mounted) return;
      setState(() {
        _flights = flights;
        _applyFilter();
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

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredFlights = List.from(_flights);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredFlights = _flights.where((flight) {
        final flightNumber = (flight['flight_number'] ?? '').toLowerCase();
        final originCity = (flight['origin_city'] ?? '').toLowerCase();
        final destCity = (flight['destination_city'] ?? '').toLowerCase();
        return flightNumber.contains(query) ||
            originCity.contains(query) ||
            destCity.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilter();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SCHEDULED':
        return ZaKuColors.gold;
      case 'BOARDING':
        return Colors.orange;
      case 'DELAYED':
        return Colors.deepOrange;
      case 'CANCELLED':
        return Colors.red;
      case 'DEPARTED':
        return Colors.blue;
      case 'LANDED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'SCHEDULED':
        return 'Запланирован';
      case 'BOARDING':
        return 'Посадка';
      case 'DELAYED':
        return 'Задержан';
      case 'CANCELLED':
        return 'Отменен';
      case 'DEPARTED':
        return 'Вылетел';
      case 'LANDED':
        return 'Приземлился';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(
    int flightId,
    String newStatus,
    String flightNumber,
  ) async {
    String? departureTime;

    // For DELAYED status, ask for new departure time
    if (newStatus == 'DELAYED') {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Новое время вылета',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Время (ISO формат)',
              hintText: '2026-01-05T10:30:00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена', style: GoogleFonts.montserrat()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ZaKuColors.gold,
                foregroundColor: ZaKuColors.burgundy,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      departureTime = controller.text.trim();
      if (departureTime.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Время вылета обязательно для статуса DELAYED'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await ApiService.staffUpdateFlightStatus(
        flightId: flightId,
        status: newStatus,
        departureTime: departureTime,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус рейса $flightNumber обновлен'),
          backgroundColor: Colors.green,
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Ошибка обновления' : msg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Управление рейсами',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFlightScreen()),
              );
              if (result == true) _load();
            },
            tooltip: 'Создать рейс',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по номеру рейса или городу...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Flights list
          Expanded(
            child: _loading
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
                      : _filteredFlights.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Нет рейсов'
                                : 'Ничего не найдено',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredFlights.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final f = _filteredFlights[index];
                              return _buildFlightCard(f);
                            },
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final flightNumber = flight['flight_number'] ?? '';
    final originCode = flight['origin_code'] ?? '';
    final originCity = flight['origin_city'] ?? '';
    final destCode = flight['destination_code'] ?? '';
    final destCity = flight['destination_city'] ?? '';
    final status = flight['status'] ?? 'SCHEDULED';
    final price = flight['price'] ?? 0.0;
    final terminal = flight['terminal'];
    final gate = flight['gate'];

    DateTime? departureTime;
    DateTime? arrivalTime;

    try {
      departureTime = DateTime.parse(flight['departure_time']);
      arrivalTime = DateTime.parse(flight['arrival_time']);
    } catch (e) {
      // ignore
    }

    final dateFormat = DateFormat('dd MMM, HH:mm', 'ru');

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
          // Header: flight number + status + menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  flightNumber,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (newStatus) {
                      _updateStatus(flight['id'], newStatus, flightNumber);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'SCHEDULED',
                        child: Text('Запланирован'),
                      ),
                      const PopupMenuItem(
                        value: 'BOARDING',
                        child: Text('Посадка'),
                      ),
                      const PopupMenuItem(
                        value: 'DELAYED',
                        child: Text('Задержан'),
                      ),
                      const PopupMenuItem(
                        value: 'CANCELLED',
                        child: Text('Отменен'),
                      ),
                      const PopupMenuItem(
                        value: 'DEPARTED',
                        child: Text('Вылетел'),
                      ),
                      const PopupMenuItem(
                        value: 'LANDED',
                        child: Text('Приземлился'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Airplane info (if available)
          if (flight['airplane_model'] != null ||
              flight['airplane_name'] != null) ...[
            Row(
              children: [
                Icon(
                  Icons.airplanemode_active,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  flight['airplane_model'] ?? flight['airplane_name'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Route
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      originCode,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      originCity,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      destCode,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      destCity,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (departureTime != null)
                Text(
                  'Вылет: ${dateFormat.format(departureTime)}',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
              if (arrivalTime != null)
                Text(
                  'Прилет: ${dateFormat.format(arrivalTime)}',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
            ],
          ),

          // Terminal/Gate
          if (terminal != null || gate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (terminal != null)
                  Text(
                    'Терминал: $terminal',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                if (terminal != null && gate != null)
                  Text(
                    '  |  ',
                    style: GoogleFonts.montserrat(color: Colors.grey[400]),
                  ),
                if (gate != null)
                  Text(
                    'Выход: $gate',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Price
          Text(
            'Цена: ${price.toStringAsFixed(0)} ₸',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ZaKuColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }
}
