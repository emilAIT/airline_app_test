import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/globe_loader.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _photos = [];
  String _selectedCategory = 'DESTINATION'; // Default category

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await _apiService.getPhotos(category: _selectedCategory);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching photos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _fetchPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EldiyarTheme.darkerBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover',
                    style: EldiyarTheme.darkTheme.textTheme.displaySmall
                        ?.copyWith(color: EldiyarTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore new destinations and fleets.',
                    style: EldiyarTheme.darkTheme.textTheme.bodyMedium
                        ?.copyWith(color: EldiyarTheme.textSecondary),
                  ),
                ],
              ),
            ),

            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildCategoryChip('DESTINATION', 'Destinations'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('AIRPORT', 'Airports'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('AIRCRAFT', 'Fleet'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gallery
            Expanded(
              child: _isLoading
                  ? const Center(child: GlobeLoader(size: 80))
                  : _photos.isEmpty
                  ? Center(
                      child: Text(
                        'No photos found.',
                        style: EldiyarTheme.darkTheme.textTheme.bodyMedium
                            ?.copyWith(color: EldiyarTheme.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        return _buildPhotoCard(photo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String categoryCode, String label) {
    final isSelected = _selectedCategory == categoryCode;
    return GestureDetector(
      onTap: () => _onCategoryChanged(categoryCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? EldiyarTheme.primaryBlue
              : EldiyarTheme.cardBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? EldiyarTheme.primaryBlue
                : EldiyarTheme.primaryBlue.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EldiyarTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: EldiyarTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : EldiyarTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(dynamic photo) {
    final String url = photo['url'] ?? '';
    // Проверяем: это ссылка из интернета или локальный файл?
    final bool isNetwork = url.startsWith('http');

    // Для локальных файлов: если URL уже содержит путь, извлекаем только имя файла
    String assetPath = url;
    if (!isNetwork) {
      // Убираем префиксы 'photos/', 'assets/photos/' если они есть
      if (url.startsWith('assets/photos/')) {
        assetPath = url.substring('assets/photos/'.length);
      } else if (url.startsWith('photos/')) {
        assetPath = url.substring('photos/'.length);
      }
      assetPath = 'assets/photos/$assetPath';
    }

    return Container(
      decoration: BoxDecoration(
        color: EldiyarTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          isNetwork
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorPlaceholder(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingIndicator(loadingProgress);
                  },
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading asset: $assetPath");
                    return _buildErrorPlaceholder();
                  },
                ),

          // Gradient Overlay (оставляем как был)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вынес заглушку ошибки, чтобы код был чище
  Widget _buildErrorPlaceholder() {
    return Container(
      color: EldiyarTheme.cardBackground,
      child: const Icon(Icons.broken_image, color: EldiyarTheme.textSecondary),
    );
  }

  // Вынес индикатор загрузки
  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
            : null,
        color: EldiyarTheme.primaryBlue,
        strokeWidth: 2,
      ),
    );
  }
}
