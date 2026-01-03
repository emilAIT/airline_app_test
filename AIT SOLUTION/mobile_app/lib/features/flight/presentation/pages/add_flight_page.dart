import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ait_airlines/features/airplane/presentation/bloc/airplane_bloc.dart';
import 'package:ait_airlines/features/airplane/presentation/bloc/airplane_event.dart';
import 'package:ait_airlines/features/airplane/presentation/bloc/airplane_state.dart';
import 'package:ait_airlines/features/airplane/domain/entities/airplane.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_bloc.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_event.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_state.dart';
import 'package:ait_airlines/features/flight/domain/entities/airport.dart';

class AddFlightPage extends StatefulWidget {
  const AddFlightPage({super.key});

  @override
  State<AddFlightPage> createState() => _AddFlightPageState();
}

class _AddFlightPageState extends State<AddFlightPage> {
  final _formKey = GlobalKey<FormState>();

  final _flightNumberController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _gateDepController = TextEditingController();
  final _gateArrController = TextEditingController();

  int? _selectedDepartureAirportId;
  int? _selectedArrivalAirportId;
  int? _selectedAirplaneId;
  DateTime? _scheduledDeparture;
  DateTime? _scheduledArrival;

  @override
  void dispose() {
    _flightNumberController.dispose();
    _basePriceController.dispose();
    _gateDepController.dispose();
    _gateArrController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<FlightBloc>().add(FetchAirports());
    context.read<AirplaneBloc>().add(FetchAirplanes());
  }

  Future<void> _selectDateTime(BuildContext context, bool isDeparture) async {
    final now = DateTime.now();

    // Для времени вылета минимальная дата - через 1 час от текущего времени
    // Для времени прибытия минимальная дата - текущее время
    final minDate = isDeparture ? now.add(const Duration(hours: 1)) : now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          minDate.isAfter(now) ? minDate : now.add(const Duration(days: 1)),
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isDeparture
          ? 'Select departure date (min 1 hour from now)'
          : 'Select arrival date',
    );
    if (pickedDate != null) {
      // Для времени вылета: если выбрана сегодняшняя дата, минимальное время должно быть через час
      TimeOfDay initialTime = TimeOfDay.now();
      if (isDeparture) {
        final today = DateTime(now.year, now.month, now.day);
        final pickedDateOnly = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
        if (pickedDateOnly == today) {
          // Если выбрана сегодняшняя дата, минимальное время - через час от текущего
          final minTime = now.add(const Duration(hours: 1));
          initialTime = TimeOfDay(hour: minTime.hour, minute: minTime.minute);
        }
      }
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: isDeparture ? 'Select departure time (min 1 hour from now)' : 'Select arrival time',
      );
      if (pickedTime != null) {
        final dt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Дополнительная проверка на фронтенде
        if (isDeparture && dt.isBefore(now.add(const Duration(hours: 1)))) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Departure time must be at least 1 hour in the future'),
            backgroundColor: Colors.orange,
          ));
          return;
        }

        if (!isDeparture && dt.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Arrival time cannot be in the past'),
            backgroundColor: Colors.orange,
          ));
          return;
        }

        setState(() {
          if (isDeparture) {
            _scheduledDeparture = dt;
            // Если время прибытия уже выбрано и оно раньше нового времени вылета, сбрасываем его
            if (_scheduledArrival != null &&
                _scheduledArrival!
                    .isBefore(dt.add(const Duration(minutes: 30)))) {
              _scheduledArrival = null;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Arrival time reset - please select arrival time after departure'),
                backgroundColor: Colors.blue,
              ));
            }
          } else {
            // Проверяем, что время прибытия после времени вылета
            if (_scheduledDeparture != null &&
                dt.isBefore(
                    _scheduledDeparture!.add(const Duration(minutes: 30)))) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Arrival time must be at least 30 minutes after departure'),
                backgroundColor: Colors.orange,
              ));
              return;
            }
            _scheduledArrival = dt;
          }
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartureAirportId == null ||
          _selectedArrivalAirportId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select airports')));
        return;
      }
      if (_selectedAirplaneId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an airplane')));
        return;
      }
      if (_scheduledDeparture == null || _scheduledArrival == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please select dates')));
        return;
      }

      // КРИТИЧЕСКАЯ ВАЛИДАЦИЯ ВРЕМЕНИ
      final now = DateTime.now();

      // Проверяем, что время вылета не в прошлом (минимум через 1 час)
      if (_scheduledDeparture!.isBefore(now.add(const Duration(hours: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Departure time must be at least 1 hour in the future'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Проверяем, что время прибытия не в прошлом
      if (_scheduledArrival!.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Arrival time cannot be in the past'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Проверяем, что время вылета раньше времени прибытия
      if (_scheduledDeparture!.isAfter(_scheduledArrival!) ||
          _scheduledDeparture!.isAtSameMomentAs(_scheduledArrival!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Departure time must be before arrival time'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Проверяем минимальную продолжительность рейса (30 минут)
      final flightDuration =
          _scheduledArrival!.difference(_scheduledDeparture!);
      if (flightDuration.inMinutes < 30) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Flight duration must be at least 30 minutes'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Проверяем, что аэропорты вылета и прибытия разные
      if (_selectedDepartureAirportId == _selectedArrivalAirportId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Departure and arrival airports must be different'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Вычисляем check_in_opens и check_in_closes в зависимости от времени до вылета
      final timeUntilDeparture = _scheduledDeparture!.difference(now);
      String checkInOpens;
      String checkInCloses;
      
      if (timeUntilDeparture <= const Duration(hours: 24)) {
        // Если рейс через 1-24 часа, открываем регистрацию сразу
        checkInOpens = now.toIso8601String();
      } else {
        // Иначе за 24 часа до вылета
        checkInOpens = _scheduledDeparture!
            .subtract(const Duration(hours: 24))
            .toIso8601String();
      }
      
      if (timeUntilDeparture <= const Duration(minutes: 10)) {
        // Если рейс через 5-10 минут, закрываем регистрацию за 3 минуты до вылета
        checkInCloses = _scheduledDeparture!
            .subtract(const Duration(minutes: 3))
            .toIso8601String();
      } else {
        // Иначе за 1 час до вылета
        checkInCloses = _scheduledDeparture!
            .subtract(const Duration(hours: 1))
            .toIso8601String();
      }

      final data = {
        'flight_number': _flightNumberController.text,
        'departure_airport_id': _selectedDepartureAirportId,
        'arrival_airport_id': _selectedArrivalAirportId,
        'scheduled_departure': _scheduledDeparture!.toIso8601String(),
        'scheduled_arrival': _scheduledArrival!.toIso8601String(),
        'airplane_id': _selectedAirplaneId,
        'base_price': double.parse(_basePriceController.text),
        'check_in_opens': checkInOpens,
        'check_in_closes': checkInCloses,
        'gate_departure': _gateDepController.text.trim(),
        'gate_arrival': _gateArrController.text.trim(),
      };

      context.read<FlightBloc>().add(CreateFlightRequested(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Schedule New Flight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<FlightBloc, FlightState>(
        listener: (context, state) {
          if (state is FlightCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flight created successfully!')));
            context.read<FlightBloc>().add(FetchFlights()); // Refresh list first
            context.pop();
          } else if (state is FlightError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _flightNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Flight Number (e.g. KC-901)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE94560)),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gateDepController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Gate Departure',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE94560)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _gateArrController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Gate Arrival',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE94560)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Airports
                BlocBuilder<FlightBloc, FlightState>(
                  buildWhen: (p, c) =>
                      c is AirportsLoaded || c is FlightLoading,
                  builder: (context, state) {
                    List<Airport> airports = [];
                    if (state is AirportsLoaded) airports = state.airports;

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedDepartureAirportId,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'From',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE94560)),
                              ),
                            ),
                            dropdownColor: const Color(0xFF16213E),
                            items: airports
                                .map<DropdownMenuItem<int>>((Airport a) =>
                                    DropdownMenuItem(
                                        value: a.id,
                                        child:
                                            Text('${a.city} (${a.iataCode})')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedDepartureAirportId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedArrivalAirportId,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'To',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE94560)),
                              ),
                            ),
                            dropdownColor: const Color(0xFF16213E),
                            items: airports
                                .map<DropdownMenuItem<int>>((Airport a) =>
                                    DropdownMenuItem(
                                        value: a.id,
                                        child:
                                            Text('${a.city} (${a.iataCode})')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedArrivalAirportId = v),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Dates
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(
                      _scheduledDeparture == null
                          ? 'Select Departure'
                          : 'Dep: ${DateFormat('dd MMM HH:mm').format(_scheduledDeparture!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_month, color: Colors.white70),
                    onTap: () => _selectDateTime(context, true),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(
                      _scheduledArrival == null
                          ? 'Select Arrival'
                          : 'Arr: ${DateFormat('dd MMM HH:mm').format(_scheduledArrival!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_month, color: Colors.white70),
                    onTap: () => _selectDateTime(context, false),
                  ),
                ),

                const SizedBox(height: 16),

                // Airplanes
                BlocBuilder<AirplaneBloc, AirplaneState>(
                  builder: (context, state) {
                    List<Airplane> airplanes = [];
                    if (state is AirplaneLoaded) airplanes = state.airplanes;

                    return DropdownButtonFormField<int>(
                      value: _selectedAirplaneId,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Assign Airplane',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE94560)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF16213E),
                      items: airplanes
                          .map<DropdownMenuItem<int>>((Airplane a) =>
                              DropdownMenuItem(
                                  value: a.id,
                                  child:
                                      Text('${a.model} (${a.registration})')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAirplaneId = v),
                      hint: const Text('Select your airplane'),
                    );
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _basePriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Base Price (USD)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixText: '\$',
                    prefixStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE94560)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'CREATE FLIGHT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
