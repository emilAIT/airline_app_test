import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/airports_provider.dart';

class AirportsScreen extends StatefulWidget {
  const AirportsScreen({super.key});

  @override
  State<AirportsScreen> createState() => _AirportsScreenState();
}

class _AirportsScreenState extends State<AirportsScreen> {
  var _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Future.microtask(() {
        context.read<AirportsProvider>().loadAll();
      });
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AirportsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Airports')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.builder(
                  itemCount: provider.airports.length,
                  itemBuilder: (ctx, i) {
                    final airport = provider.airports[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(airport.code),
                      ),
                      title: Text(airport.name),
                      subtitle: Text('${airport.city}, ${airport.country}'),
                    );
                  },
                ),
    );
  }
}
