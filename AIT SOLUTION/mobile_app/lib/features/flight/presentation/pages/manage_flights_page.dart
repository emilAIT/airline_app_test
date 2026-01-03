import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_bloc.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_event.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_state.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';

class ManageFlightsPage extends StatefulWidget {
  const ManageFlightsPage({super.key});

  @override
  State<ManageFlightsPage> createState() => _ManageFlightsPageState();
}

class _ManageFlightsPageState extends State<ManageFlightsPage> {
  @override
  void initState() {
    super.initState();
    context.read<FlightBloc>().add(FetchFlights());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'My Flights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated && state.user.role == 'staff') {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/flights/add'),
              label: const Text('Add Flight', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color(0xFFE94560),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocListener<FlightBloc, FlightState>(
        listener: (context, state) {
          if (state is FlightUpdated) {
            // Refresh flights list after update
            context.read<FlightBloc>().add(FetchFlights());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Flight updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is FlightError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: BlocBuilder<FlightBloc, FlightState>(
          builder: (context, state) {
            if (state is FlightLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE94560)),
              );
            } else if (state is FlightsLoaded) {
              final flights = state.flights;
              if (flights.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flight_takeoff, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'No flights managed yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add a flight to get started!',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: flights.length,
                itemBuilder: (context, index) {
                  final flight = flights[index];
                  final authState = context.read<AuthBloc>().state;
                  final isStaff = authState is AuthAuthenticated && authState.user.role == 'staff';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (isStaff) {
                              // Navigate to passengers page for staff
                              context.push('/flights/${flight.id}/passengers');
                            } else {
                              // For passengers: navigate to seat selection
                              context.push('/flights/${flight.id}/seats', extra: flight);
                            }
                          },
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE94560).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flight_takeoff, color: Color(0xFFE94560), size: 24),
                          ),
                          title: Text(
                            '${flight.flightNumber} | ${flight.departureAirport.city} (${flight.departureAirport.iataCode}) → ${flight.arrivalAirport.city} (${flight.arrivalAirport.iataCode})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Departure: ${DateFormat('dd MMM, HH:mm').format(flight.scheduledDeparture)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Airplane: ${flight.airplane.model} (${flight.airplane.registration})',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Gate: ${flight.gateDeparture ?? 'N/A'} → ${flight.gateArrival ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(flight.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              flight.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(flight.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        // Action buttons for staff
                        if (isStaff)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showStatusDialog(context, flight.id, flight.status),
                                    icon: const Icon(Icons.update, size: 18),
                                    label: const Text('Change Status', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showGateDialog(context, flight),
                                    icon: const Icon(Icons.door_front_door, size: 18),
                                    label: const Text('Change Gate', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                      onPressed: () => context.read<FlightBloc>().add(FetchFlights()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text(
                'Nothing to show',
                style: TextStyle(color: Colors.white60),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, int flightId, String currentStatus) {
    final statuses = ['scheduled', 'boarding', 'delayed', 'departed', 'landed', 'finished', 'cancelled'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Flight Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              title: Text(status.toUpperCase()),
              leading: status == currentStatus ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<FlightBloc>().add(UpdateFlightStatusRequested(
                  flightId: flightId,
                  status: status,
                ));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled': return Colors.blue;
      case 'boarding': return Colors.orange;
      case 'departed': return Colors.green;
      case 'landed': return Colors.grey;
      case 'finished': return Colors.purple;
      case 'cancelled': return Colors.red;
      case 'delayed': return Colors.amber;
      default: return Colors.black;
    }
  }

  void _showGateDialog(BuildContext context, flight) {
    final depCtrl = TextEditingController(text: flight.gateDeparture ?? '');
    final arrCtrl = TextEditingController(text: flight.gateArrival ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Gate for ${flight.flightNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Gate departure'), controller: depCtrl),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Gate arrival'), controller: arrCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<FlightBloc>().add(UpdateFlightGatesRequested(flight.id, depCtrl.text.trim(), arrCtrl.text.trim()));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
