import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/flight_cubit.dart';
import 'flight_details_screen.dart';

class FlightResultsScreen extends StatelessWidget {
  const FlightResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Flights')),
      body: BlocBuilder<FlightCubit, FlightState>(
        builder: (context, state) {
          if (state is FlightLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FlightError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is FlightSearchResults) {
            if (state.flights.isEmpty) {
              return const Center(child: Text('No flights found for these criteria.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.flights.length,
              itemBuilder: (context, index) {
                final flight = state.flights[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FlightCard(
                    flight: flight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlightDetailsScreen(flightId: flight.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class FlightCard extends StatelessWidget {
  final dynamic flight; // Using dynamic or the Flight entity
  final VoidCallback onTap;

  const FlightCard({super.key, required this.flight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AirportInfo(
                    code: flight.origin.code,
                    city: flight.origin.city,
                    align: CrossAxisAlignment.start,
                  ),
                  Column(
                    children: [
                      Icon(Icons.airplanemode_active, color: Theme.of(context).colorScheme.primary),
                      Container(width: 80, height: 1, color: Colors.grey[300]),
                      Text(flight.flightNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _AirportInfo(
                    code: flight.destination.code,
                    city: flight.destination.city,
                    align: CrossAxisAlignment.end,
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEPARTURE', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(
                        DateFormat('HH:mm').format(flight.scheduledDeparture),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        DateFormat('d MMM').format(flight.scheduledDeparture),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('SELECT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirportInfo extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment align;

  const _AirportInfo({required this.code, required this.city, required this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          code,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(city, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
