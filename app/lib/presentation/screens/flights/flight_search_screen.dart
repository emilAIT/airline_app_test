import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:airline_app/data/repositories/flight_repository.dart';
import 'package:airline_app/domain/entities/flight_assets.dart';
import 'package:airline_app/presentation/cubits/flight_cubit.dart';
import 'package:airline_app/presentation/screens/flights/flight_results_screen.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  Airport? _selectedOrigin;
  Airport? _selectedDestination;
  DateTime? _selectedDate;
  List<Airport> _airports = [];
  bool _isLoadingAirports = true;

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    try {
      final airports = await context.read<FlightRepository>().getAirports();
      setState(() {
        _airports = airports;
        _isLoadingAirports = false;
      });
    } catch (e) {
      setState(() => _isLoadingAirports = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load airports: $e')),
        );
      }
    }
  }

  void _onSearch() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select origin and destination airports')),
      );
      return;
    }

    if (_selectedOrigin!.id == _selectedDestination!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Origin and destination must be different')),
      );
      return;
    }

    context.read<FlightCubit>().searchFlights(
          originId: _selectedOrigin!.id,
          destinationId: _selectedDestination!.id,
          date: _selectedDate,
        );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlightResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAirports) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Where to next?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<Airport>(
            value: _selectedOrigin,
            decoration: const InputDecoration(
              labelText: 'From',
              prefixIcon: Icon(Icons.flight_takeoff),
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select origin airport'),
            items: _airports.map((airport) {
              return DropdownMenuItem<Airport>(
                value: airport,
                child: Text('${airport.city} (${airport.code})'),
              );
            }).toList(),
            onChanged: (airport) {
              setState(() => _selectedOrigin = airport);
            },
            isExpanded: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Airport>(
            value: _selectedDestination,
            decoration: const InputDecoration(
              labelText: 'To',
              prefixIcon: Icon(Icons.flight_land),
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select destination airport'),
            items: _airports.map((airport) {
              return DropdownMenuItem<Airport>(
                value: airport,
                child: Text('${airport.city} (${airport.code})'),
              );
            }).toList(),
            onChanged: (airport) {
              setState(() => _selectedDestination = airport);
            },
            isExpanded: true,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Departure Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('EEE, d MMM yyyy').format(_selectedDate!),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _onSearch,
            child: const Text('SEARCH FLIGHTS'),
          ),
        ],
      ),
    );
  }
}
