import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/flights_provider.dart';
import '../core/widgets/app_drawer.dart';
import 'passenger/flight_details_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _searched = false;
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  DateTime? departureDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        departureDate = picked;
      });
    }
  }

  void _onSearch() {
    context.read<FlightsProvider>().load(
      origin: originController.text,
      destination: destinationController.text,
      departureDate: departureDate,
    );
    setState(() {
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SkyFlow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Background Gradient/Image
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Where to next?',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover your next adventure',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Search Card
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SearchForm(
                        originController: originController,
                        destinationController: destinationController,
                        departureDate: departureDate,
                        onPickDate: _pickDate,
                        onSearch: _onSearch,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Results or Promotions
                  if (_searched) ...[
                    Text(
                      'Search Results',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Consumer<FlightsProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (provider.error != null) {
                          return Center(child: Text(provider.error!, style: TextStyle(color: theme.colorScheme.error)));
                        }
                        if (provider.flights.isEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No flights found.', style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.flights.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final flight = provider.flights[index];
                            return FlightCard(
                              flight: flight,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FlightDetailsScreen(flightId: flight.id),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ] else ...[
                     // Popular destinations removed by request
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, String city, String code, String imageUrl) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(code, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchForm extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final DateTime? departureDate;
  final VoidCallback onPickDate;
  final VoidCallback onSearch;

  const SearchForm({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.departureDate,
    required this.onPickDate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: originController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flight_takeoff),
                      hintText: 'JFK',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flight_land),
                      hintText: 'LHR',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  departureDate != null ? DateFormat('EEE, MMM d, y').format(departureDate!) : 'Select Date',
                  style: TextStyle(
                    color: departureDate != null ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onSearch,
            child: const Text('Search Flights'),
          ),
        ),
      ],
    );
  }
}

class FlightCard extends StatelessWidget {
  final dynamic flight;
  final VoidCallback onTap;

  const FlightCard({super.key, required this.flight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dep = flight.departureTime;
    final arr = flight.arrivalTime;
    final duration = arr.difference(dep);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('HH:mm').format(dep), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM d, y').format(dep), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(flight.originCode, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  children: [
                    Text('${duration.inHours}h ${duration.inMinutes % 60}m', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Icon(Icons.flight_takeoff, color: Colors.grey),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('HH:mm').format(arr), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM d, y').format(arr), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(flight.destinationCode, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${flight.price}', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary)),
                Text(flight.flightNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

