import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EvidenceGrid extends StatefulWidget {
  final List<Map<String, String>> images; // [{ 'path': '...', 'source': 'CAMERA|GALLERY|SCREENSHOT' }]
  final Function(List<Map<String, String>>) onImagesChanged;
  final Function(Map<String, String>)? onImageDelete;
  final int maxImages;
  final bool readOnly;

  const EvidenceGrid({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.onImageDelete,
    this.maxImages = 6,
    this.readOnly = false,
  });

  @override
  State<EvidenceGrid> createState() => _EvidenceGridState();
}

class _EvidenceGridState extends State<EvidenceGrid> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLostData();
    });
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;
      _processImage(response.file!, 'CAMERA');
    } catch (e) {
      debugPrint("Error recuperando datos: $e");
    }
  }

  Future<void> _processImage(XFile photo, String source) async {
    try {
      final String path = photo.path;
      final newImages = List<Map<String, String>>.from(widget.images);
      
      if (!newImages.any((img) => img['path'] == path)) {
        newImages.add({'path': path, 'source': source});
        widget.onImagesChanged(newImages);
      }
    } catch (e) {
      debugPrint('Error al procesar imagen: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      if (photo != null) {
        await _processImage(photo, source == ImageSource.camera ? 'CAMERA' : 'GALLERY');
      }
    } catch (e) {
      debugPrint('Error capturando imagen: $e');
    }
  }

  void _removeImage(Map<String, String> itemToRemove) {
    final newImages = List<Map<String, String>>.from(widget.images);
    newImages.removeWhere((img) => img['path'] == itemToRemove['path']);
    widget.onImagesChanged(newImages);
    if (widget.onImageDelete != null) {
      widget.onImageDelete!(itemToRemove);
    }
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtramos las imágenes que no son SCREENSHOT para mostrarlas en la UI
    final displayImages = widget.images.where((img) => img['source'] != 'SCREENSHOT').toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayImages.length + (displayImages.length < widget.maxImages && !widget.readOnly ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayImages.length) {
          return _buildAddButton();
        }
        return _buildImageItem(displayImages[index]);
      },
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showSourceSelector,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageItem(Map<String, String> imageData) {
    final String imagePath = imageData['path'] ?? '';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(imagePath),
        ),
        if (!widget.readOnly)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(imageData),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath) {
    final file = File(imagePath);
    return Image.file(
      file,
      key: ValueKey(imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      cacheWidth: 250,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
