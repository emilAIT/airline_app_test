import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class StaffAirportsScreen extends StatefulWidget {
  const StaffAirportsScreen({super.key});

  @override
  State<StaffAirportsScreen> createState() => _StaffAirportsScreenState();
}

class _StaffAirportsScreenState extends State<StaffAirportsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _airports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final airports = await _api.getStaffAirports();
      setState(() {
        _airports = airports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading airports: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: EldiyarTheme.primaryBlue,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Manage Airports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: EldiyarTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: EldiyarTheme.primaryBlue,
                        size: 32,
                      ),
                      onPressed: () => _showCreateDialog(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : _airports.isEmpty
                    ? const Center(
                        child: Text(
                          'No airports found',
                          style: TextStyle(color: EldiyarTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: EldiyarTheme.primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _airports.length,
                          itemBuilder: (context, index) {
                            final airport = _airports[index];
                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: EldiyarTheme.primaryBlue
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: EldiyarTheme.primaryBlue
                                              .withOpacity(0.5),
                                        ),
                                        image: airport['image_url'] != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    airport['image_url']),
                                                fit: BoxFit.cover,
                                                colorFilter: ColorFilter.mode(
                                                  Colors.black.withOpacity(0.4),
                                                  BlendMode.darken,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        airport['code'],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          airport['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: EldiyarTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${airport['city']}, ${airport['country']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: EldiyarTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: EldiyarTheme.cardBackground,
          title: const Text(
            'Create Airport',
            style: TextStyle(color: EldiyarTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Airport Code (IATA)',
                    hintText: 'e.g., FRU, DXB',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Airport Name',
                    hintText: 'e.g., Manas International Airport',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g., Bishkek',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    hintText: 'e.g., Kyrgyzstan',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                    hintText: 'e.g., https://example.com/image.jpg',
                    labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
                  ),
                  style: const TextStyle(color: EldiyarTheme.textPrimary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: EldiyarTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (codeController.text.isEmpty ||
                          nameController.text.isEmpty ||
                          cityController.text.isEmpty ||
                          countryController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: EldiyarTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await _api.createAirport({
                          'code': codeController.text.toUpperCase(),
                          'name': nameController.text,
                          'city': cityController.text,
                          'country': countryController.text,
                          'image_url': imageUrlController.text.isNotEmpty
                              ? imageUrlController.text
                              : null,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Airport created successfully!'),
                              backgroundColor: EldiyarTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: EldiyarTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: EldiyarTheme.primaryBlue.withOpacity(0.2),
                foregroundColor: EldiyarTheme.primaryBlue,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          EldiyarTheme.primaryBlue,
                        ),
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
