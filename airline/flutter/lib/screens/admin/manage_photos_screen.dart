import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ManagePhotosScreen extends StatefulWidget {
  const ManagePhotosScreen({super.key});

  @override
  State<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _photos = [];
  String _selectedCategoryFilter = 'ALL';

  // Upload Form
  bool _isUploading = false;
  File? _selectedFile;
  String _uploadCategory = 'DESTINATION';
  String? _uploadEntityType;
  final TextEditingController _entityIdController = TextEditingController();

  final List<String> _categories = ['DESTINATION', 'AIRPORT', 'AIRCRAFT', 'BRAND'];

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() => _isLoading = true);
    try {
      final category = _selectedCategoryFilter == 'ALL' ? null : _selectedCategoryFilter;
      final photos = await _apiService.getPhotos(category: category);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
         // Handle both web and mobile paths?
         // On mobile/desktop result.files.single.path is available.
         // On web, bytes are available. 
         // Since this is likely a mobile/desktop app structure (path usage in ApiService), we assume path
         if (result.files.single.path != null) {
            _selectedFile = File(result.files.single.path!);
         }
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    try {
      await _apiService.uploadPhoto(
        filePath: _selectedFile!.path,
        category: _uploadCategory,
        entityType: _uploadEntityType?.isEmpty == true ? null : _uploadEntityType,
        entityId: int.tryParse(_entityIdController.text),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded!')));
      
      // Reset form
      setState(() {
        _selectedFile = null;
        _entityIdController.clear();
      });
      
      _fetchPhotos(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(int id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: EldiyarTheme.cardBackground,
          title: Text('Delete Photo?', style: TextStyle(color: EldiyarTheme.textPrimary)),
          content: Text('Are you sure you want to delete this photo?', style: TextStyle(color: EldiyarTheme.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: EldiyarTheme.errorRed))),
          ],
        ));

    if (confirmed != true) return;

    try {
      await _apiService.deletePhoto(id);
      _fetchPhotos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: EldiyarTheme.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upload New Photo',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null && result.files.single.path != null) {
                              setModalState(() {
                                _selectedFile = File(result.files.single.path!);
                              });
                            }
                          },
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: _selectedFile != null 
                                  ? null 
                                  : EldiyarTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: EldiyarTheme.primaryBlue.withOpacity(0.3),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              image: _selectedFile != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _selectedFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: EldiyarTheme.primaryBlue,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to select image',
                                        style: TextStyle(
                                          color: EldiyarTheme.primaryBlue.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setModalState(() => _selectedFile = null);
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Change Image'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: _uploadCategory,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setModalState(() => _uploadCategory = val!),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          onChanged: (val) => _uploadEntityType = val,
                          decoration: const InputDecoration(
                            labelText: 'Entity Type (Optional)',
                            hintText: 'e.g., airport, city',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _entityIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Entity ID (Optional)',
                            hintText: 'e.g., 1',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_selectedFile != null && !_isUploading)
                                ? () async {
                                    setModalState(() => _isUploading = true);
                                    await _uploadPhoto();
                                    setModalState(() => _isUploading = false);
                                    if (mounted) Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EldiyarTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'UPLOAD PHOTO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Photos'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadModal,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Photo'),
        backgroundColor: EldiyarTheme.primaryBlue,
      ),
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
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: ['ALL', ..._categories].map((c) {
                    final isSelected = _selectedCategoryFilter == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategoryFilter = c);
                            _fetchPhotos();
                          }
                        },
                        checkmarkColor: Colors.white,
                        selectedColor: EldiyarTheme.primaryBlue,
                        backgroundColor: EldiyarTheme.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : EldiyarTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected 
                                ? EldiyarTheme.primaryBlue 
                                : EldiyarTheme.textSecondary.withOpacity(0.3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Photo Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _photos.isEmpty 
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, 
                                  size: 64, 
                                  color: EldiyarTheme.textSecondary.withOpacity(0.5)
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No photos found',
                                  style: TextStyle(color: EldiyarTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Bottom padding for FAB
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 columns looks better on mobile
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8, // Taller items
                            ),
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        photo['url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, _, __) => Container(
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.broken_image, color: Colors.white),
                                        ),
                                      ),
                                      // Gradient Overlay
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 80,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.9),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Delete Button
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: () => _deletePhoto(photo['id']),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Category Label
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8, 
                                                vertical: 4
                                              ),
                                              decoration: BoxDecoration(
                                                color: EldiyarTheme.primaryBlue,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                photo['category'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (photo['entity_type'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${photo['entity_type']} #${photo['entity_id'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
