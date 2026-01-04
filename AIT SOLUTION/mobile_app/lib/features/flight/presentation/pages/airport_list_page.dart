import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/flight_bloc.dart';
import '../bloc/flight_event.dart';
import '../bloc/flight_state.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';

class AirportListPage extends StatefulWidget {
  const AirportListPage({super.key});

  @override
  State<AirportListPage> createState() => _AirportListPageState();
}

class _AirportListPageState extends State<AirportListPage> {
  @override
  void initState() {
    super.initState();
    context.read<FlightBloc>().add(FetchAirports());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'GLOBAL AIRPORTS',
          style: TextStyle(letterSpacing: 2, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              navigateToHome(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => navigateToHome(context),
            tooltip: 'Home',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<FlightBloc>().add(FetchAirports()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/airports/add'),
        backgroundColor: const Color(0xFFE94560),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<FlightBloc, FlightState>(
        builder: (context, state) {
          if (state is FlightLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)));
          } else if (state is AirportsLoaded) {
            if (state.airports.isEmpty) {
              return const Center(child: Text('No airports registered.', style: TextStyle(color: Colors.white54)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.airports.length,
              itemBuilder: (context, index) {
                final airport = state.airports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.tealAccent,
                      child: Icon(Icons.location_on, color: Colors.black),
                    ),
                    title: Text(
                      '${airport.name} (${airport.iataCode})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${airport.city}, ${airport.country} | ${airport.timezone}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                );
              },
            );
          } else if (state is FlightError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FlightBloc>().add(FetchAirports()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flight_takeoff, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text(
                  'Start adding airports',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
