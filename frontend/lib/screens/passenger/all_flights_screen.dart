import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/flights_provider.dart';
import '../homepage_screen.dart'; // Reuse FlightCard

class AllFlightsScreen extends StatefulWidget {
  const AllFlightsScreen({super.key});

  @override
  State<AllFlightsScreen> createState() => _AllFlightsScreenState();
}

class _AllFlightsScreenState extends State<AllFlightsScreen> {
  var _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Future.microtask(() {
        context.read<FlightsProvider>().loadAll();
      });
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlightsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Flights')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.flights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) {
                    final flight = provider.flights[i];
                    return FlightCard(
                      flight: flight, 
                      onTap: () {
                         // Navigation to details if needed
                      }
                    );
                  },
                ),
    );
  }
}
