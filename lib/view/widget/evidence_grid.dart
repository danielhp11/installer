import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EvidenceGrid extends StatefulWidget {
  final List<String> images; // Base64 strings
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final bool readOnly;

  const EvidenceGrid({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 6,
    this.readOnly = false,
  });

  @override
  State<EvidenceGrid> createState() => _EvidenceGridState();
}

class _EvidenceGridState extends State<EvidenceGrid> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final newImages = List<String>.from(widget.images);
        newImages.add(base64Image);
        
        widget.onImagesChanged(newImages);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al capturar imagen')),
        );
      }
    }
  }

  void _removeImage(int index) {
    final newImages = List<String>.from(widget.images);
    newImages.removeAt(index);
    widget.onImagesChanged(newImages);
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.images.length + (widget.images.length < widget.maxImages && !widget.readOnly ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == widget.images.length) {
              return _buildAddButton();
            }
            return _buildImageItem(index);
          },
        ),
        if (widget.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${widget.images.length}/${widget.maxImages} imágenes',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showSourceSelector,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(base64Decode(widget.images[index])),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (!widget.readOnly)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
