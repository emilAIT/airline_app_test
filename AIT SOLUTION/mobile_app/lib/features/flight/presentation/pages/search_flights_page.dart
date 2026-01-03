import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_bloc.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_event.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_state.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:go_router/go_router.dart';

class SearchFlightsPage extends StatefulWidget {
  final String? initialDeparture;
  final String? initialArrival;
  final DateTime? initialDate;
  final int? initialPax;

  const SearchFlightsPage({
    super.key,
    this.initialDeparture,
    this.initialArrival,
    this.initialDate,
    this.initialPax,
  });

  @override
  State<SearchFlightsPage> createState() => _SearchFlightsPageState();
}

class _SearchFlightsPageState extends State<SearchFlightsPage> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime? _date;
  int _pax = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialDeparture != null)
      _fromCtrl.text = widget.initialDeparture!;
    if (widget.initialArrival != null) _toCtrl.text = widget.initialArrival!;
    if (widget.initialDate != null) _date = widget.initialDate;
    if (widget.initialPax != null) _pax = widget.initialPax!;
    _search();
  }

  void _search() {
    context.read<FlightBloc>().add(FetchFlights(
          departure: _fromCtrl.text.isNotEmpty ? _fromCtrl.text : null,
          arrival: _toCtrl.text.isNotEmpty ? _toCtrl.text : null,
          date: _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : null,
          passengersCount: _pax,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Flights'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: BlocBuilder<FlightBloc, FlightState>(
              builder: (context, state) {
                if (state is FlightLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FlightsLoaded) {
                  if (state.flights.isEmpty) {
                    return const Center(child: Text('No flights'));
                  }
                  return ListView.builder(
                    itemCount: state.flights.length,
                    itemBuilder: (_, i) => _tile(state.flights[i]),
                  );
                } else if (state is FlightError) {
                  return Center(
                      child: Text(state.message,
                          style: const TextStyle(color: Colors.red)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _fromCtrl,
                      decoration: const InputDecoration(
                          labelText: 'From (city/code)'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _toCtrl,
                      decoration:
                          const InputDecoration(labelText: 'To (city/code)'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(_date != null
                        ? DateFormat('yyyy-MM-dd').format(_date!)
                        : 'Any'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _pax > 1 ? () => setState(() => _pax--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_pax pax'),
                  IconButton(
                    onPressed: () => setState(() => _pax++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _search, child: const Text('Search')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(Flight f) {
    // Проверяем, доступен ли рейс для бронирования
    // Используем UTC время для согласованности с backend
    final now = DateTime.now().toUtc();

    // ИСПРАВЛЕННАЯ ЛОГИКА:
    // 1. Рейс должен быть в статусе SCHEDULED
    // 2. Должны быть свободные места
    // 3. Время вылета должно быть в будущем
    // 4. Регистрация не должна быть закрыта (если установлена)

    // Приводим scheduledDeparture к UTC для правильного сравнения
    DateTime departureTime = f.scheduledDeparture;
    if (!departureTime.isUtc) {
      departureTime = departureTime.toUtc();
    }
    bool isFlightInFuture = departureTime.isAfter(now);
    bool hasAvailableSeats = f.availableSeats > 0;
    bool isScheduled = f.status.toLowerCase() == 'scheduled';

    bool isCheckInClosed = false;
    if (f.checkInCloses != null) {
      // Приводим checkInCloses к UTC для правильного сравнения
      DateTime checkInClosesTime = f.checkInCloses!;
      if (!checkInClosesTime.isUtc) {
        checkInClosesTime = checkInClosesTime.toUtc();
      }
      isCheckInClosed = checkInClosesTime.isBefore(now);
    }

    // Рейс доступен если все условия выполнены
    final isAvailable = isScheduled &&
        isFlightInFuture &&
        hasAvailableSeats &&
        !isCheckInClosed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          '${f.flightNumber} | ${f.departureAirport.city} → ${f.arrivalAirport.city}',
          style: TextStyle(
            color: isAvailable ? null : Colors.grey,
            decoration: isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dep: ${DateFormat('dd MMM, HH:mm').format(f.scheduledDeparture)}',
              style: TextStyle(color: isAvailable ? null : Colors.grey),
            ),
            Text(
              'Gate: ${f.gateDeparture ?? ''} → ${f.gateArrival ?? ''}',
              style: TextStyle(color: isAvailable ? null : Colors.grey),
            ),
            Text(
              'Class: economy/business | Seats: ${f.availableSeats}',
              style: TextStyle(color: isAvailable ? null : Colors.grey),
            ),
            if (!isAvailable) ...[
              if (!isScheduled)
                const Text(
                  'Flight status: Not available for booking',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              if (!isFlightInFuture)
                const Text(
                  'Flight has already departed',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              if (!hasAvailableSeats)
                const Text(
                  'No seats available',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              if (isCheckInClosed)
                const Text(
                  'Booking closed - check-in period ended',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
            ],
          ],
        ),
        trailing: isAvailable
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.block, color: Colors.red),
        onTap: isAvailable
            ? () => context.push('/flights/${f.id}/seats', extra: {
                  'flight': f,
                  'passengersCount': _pax,
                })
            : () {
                String reason = 'This flight is not available for booking';
                if (!isScheduled)
                  reason = 'Flight is not in scheduled status';
                else if (!isFlightInFuture)
                  reason = 'Flight has already departed';
                else if (!hasAvailableSeats)
                  reason = 'No seats available';
                else if (isCheckInClosed) reason = 'Check-in period has ended';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reason),
                    backgroundColor: Colors.red,
                  ),
                );
              },
      ),
    );
  }
}
