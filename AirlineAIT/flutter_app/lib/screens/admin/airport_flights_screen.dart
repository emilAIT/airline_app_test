import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class AirportFlightsScreen extends StatefulWidget {
  final int airportId;
  final String airportCode;
  final String airportName;

  const AirportFlightsScreen({
    super.key,
    required this.airportId,
    required this.airportCode,
    required this.airportName,
  });

  @override
  State<AirportFlightsScreen> createState() => _AirportFlightsScreenState();
}

class _AirportFlightsScreenState extends State<AirportFlightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFlights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getAirportFlights(widget.airportId);

      if (mounted) {
        setState(() {
          _data = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load flights';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Richer blue
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.airportCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Text(widget.airportName, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.flight_takeoff),
              text: 'Departures (${_data?['summary']?['total_departures'] ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.flight_land),
              text: 'Arrivals (${_data?['summary']?['total_arrivals'] ?? 0})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadFlights, child: const Text('Retry')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFlightList(_data?['departures'] ?? [], isDeparture: true),
                    _buildFlightList(_data?['arrivals'] ?? [], isDeparture: false),
                  ],
                ),
    );
  }

  Widget _buildFlightList(List<dynamic> flights, {required bool isDeparture}) {
    if (flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDeparture ? Icons.flight_takeoff : Icons.flight_land,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isDeparture ? 'departures' : 'arrivals'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFlights,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: flights.length,
        itemBuilder: (context, index) {
          final flight = flights[index];
          return _buildFlightCard(flight, isDeparture: isDeparture);
        },
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight, {required bool isDeparture}) {
    final status = flight['status'] ?? 'UNKNOWN';
    final flightNumber = flight['flight_number'] ?? '---';
    final otherAirport = flight['other_airport'] ?? {};
    final airplane = flight['airplane'] ?? {};
    
    final time = isDeparture
        ? DateTime.parse(flight['departure_time'])
        : DateTime.parse(flight['arrival_time']);
    final formattedTime = DateFormat('HH:mm').format(time);
    final formattedDate = DateFormat('MMM dd').format(time);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Time column
            Container(
              width: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Flight info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        flightNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isDeparture ? Icons.arrow_forward : Icons.arrow_back,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${otherAirport['code'] ?? '---'} - ${otherAirport['city'] ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${airplane['model'] ?? 'Unknown'} (${airplane['registration'] ?? '---'})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Gate/Terminal
            if (flight['gate'] != null || flight['terminal'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (flight['gate'] != null)
                    Text('Gate ${flight['gate']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (flight['terminal'] != null)
                    Text('T${flight['terminal']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'BOARDING':
        return const Color(0xFFF57C00); // Darker Orange
      case 'DEPARTED':
        return const Color(0xFF1976D2); // Rich Blue
      case 'LANDED':
        return const Color(0xFF388E3C); // Green 700
      case 'DELAYED':
        return const Color(0xFFD32F2F); // Red 700
      case 'CANCELLED':
        return const Color(0xFF757575); // Grey 600
      case 'SCHEDULED':
      default:
        return const Color(0xFF00796B); // Teal 700
    }
  }
}
